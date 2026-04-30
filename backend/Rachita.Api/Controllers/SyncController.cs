using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Rachita.Core.Entities;
using Rachita.Infrastructure.Data;
using System.Security.Claims;

namespace Rachita.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class SyncController : ControllerBase
{
    private readonly AppDbContext _context;

    public SyncController(AppDbContext context)
    {
        _context = context;
    }

    private Guid GetCurrentClinicId()
    {
        var clinicClaim = User.FindFirst("ClinicId")?.Value;
        if (clinicClaim != null && Guid.TryParse(clinicClaim, out Guid clinicId))
            return clinicId;
        throw new UnauthorizedAccessException("Clinic ID is missing from token.");
    }

    /// <summary>
    /// Push changes from Local SQLite device to Server with high precision
    /// </summary>
    [HttpPost("push")]
    public async Task<IActionResult> Push([FromBody] SyncPushPayload payload)
    {
        var clinicId = GetCurrentClinicId();
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            // 1. Process Patients (strict clinic isolation)
            if (payload.Patients != null)
            {
                foreach (var p in payload.Patients)
                {
                    p.ClinicId = clinicId; // Strict Isolation
                    var existing = await _context.Patients.FirstOrDefaultAsync(x => x.Id == p.Id && x.ClinicId == clinicId);

                    if (existing == null)
                    {
                        _context.Patients.Add(p);
                        LogAudit(clinicId, "Patient", p.Id, "Insert", userId);
                    }
                    else if (p.LastModifiedAt >= existing.LastModifiedAt)
                    {
                        var safeClinicId = existing.ClinicId; 
                        _context.Entry(existing).CurrentValues.SetValues(p);
                        existing.ClinicId = safeClinicId;
                        existing.IsDeleted = p.IsDeleted; // Explicitly ensure this is updated
                        LogAudit(clinicId, "Patient", p.Id, "Update", userId);
                    }
                }
            }

            // ─── CRITICAL CHECKPOINT ──────────────────────────────────────────────────
            // EF Core's AnyAsync() reads from the DATABASE, not the in-memory ChangeTracker.
            // Patients added above are NOT visible to later AnyAsync calls unless we save first.
            // Without this SaveChanges, newly-added patients will fail the FK check below
            // leading to prescription rejections or mysterious PK violations on batch commit.
            await _context.SaveChangesAsync();

            // 2. Process Prescriptions (Nested Data: Medicines & Vitals)
            var batchMedIds   = new HashSet<Guid>();
            var batchVitalIds = new HashSet<Guid>();

            if (payload.Prescriptions != null)
            {
                Guid.TryParse(userId, out Guid doctorIdGuid);

                foreach (var rx in payload.Prescriptions)
                {
                    rx.DoctorId = doctorIdGuid;
                    rx.ClinicId = clinicId; // Isolate Prescription to the logged-in Clinic

                    var patientExists = await _context.Patients.AnyAsync(p => p.Id == rx.PatientId && p.ClinicId == clinicId);
                    if (!patientExists) 
                    {
                        throw new Exception($"Cannot sync prescription {rx.Id}: Patient {rx.PatientId} not found in this clinic.");
                    }

                    var existingRx = await _context.Prescriptions
                        .Include(r => r.PrescriptionMedicines)
                        .Include(r => r.VitalSign)
                        .FirstOrDefaultAsync(x => x.Id == rx.Id);

                    if (existingRx == null)
                    {
                        // 1. INSERT Logic for NEW Prescription
                        if (rx.VitalSign != null) 
                        {
                            rx.VitalSign.PrescriptionId = rx.Id;
                            // VitalSign ID Collision Check
                            if (batchVitalIds.Contains(rx.VitalSign.Id) || await _context.VitalSigns.AsNoTracking().AnyAsync(v => v.Id == rx.VitalSign.Id))
                            {
                                rx.VitalSign.Id = Guid.NewGuid();
                            }
                            batchVitalIds.Add(rx.VitalSign.Id);
                        }

                        foreach (var med in rx.PrescriptionMedicines) 
                        {
                            med.PrescriptionId = rx.Id;
                            // Medicine ID Collision Check (Global)
                            if (batchMedIds.Contains(med.Id) || await _context.PrescriptionMedicines.AsNoTracking().AnyAsync(m => m.Id == med.Id))
                            {
                                med.Id = Guid.NewGuid(); // Resolve PK conflict by re-generating
                            }
                            batchMedIds.Add(med.Id);
                        }

                        _context.Prescriptions.Add(rx);
                        LogAudit(clinicId, "Prescription", rx.Id, "Insert", userId);
                    }
                    else if (rx.LastModifiedAt > existingRx.LastModifiedAt)
                    {
                        // 2. UPDATE Logic for Existing Prescription
                        _context.Entry(existingRx).CurrentValues.SetValues(rx);

                        // Update VitalSign
                        if (rx.VitalSign != null)
                        {
                            rx.VitalSign.PrescriptionId = rx.Id; 
                            
                            if (existingRx.VitalSign == null)
                            {
                                if (batchVitalIds.Contains(rx.VitalSign.Id) || await _context.VitalSigns.AsNoTracking().AnyAsync(v => v.Id == rx.VitalSign.Id))
                                    rx.VitalSign.Id = Guid.NewGuid();
                                
                                existingRx.VitalSign = rx.VitalSign;
                                batchVitalIds.Add(rx.VitalSign.Id);
                            }
                            else
                            {
                                // Sync values to existing record, keep ID to avoid change
                                var targetId = existingRx.VitalSign.Id;
                                _context.Entry(existingRx.VitalSign).CurrentValues.SetValues(rx.VitalSign);
                                existingRx.VitalSign.Id = targetId;
                                batchVitalIds.Add(targetId);
                            }
                        }

                        // State-Aware Upsert for Medications (High Precision)
                        var incomingMedIds = rx.PrescriptionMedicines.Select(m => m.Id).ToHashSet();
                        
                        // Delete orphans
                        var orphans = existingRx.PrescriptionMedicines.Where(m => !incomingMedIds.Contains(m.Id)).ToList();
                        if (orphans.Any()) _context.PrescriptionMedicines.RemoveRange(orphans);

                        foreach (var med in rx.PrescriptionMedicines)
                        {
                            med.PrescriptionId = rx.Id;
                            var existingMed = existingRx.PrescriptionMedicines.FirstOrDefault(m => m.Id == med.Id);

                            if (existingMed != null)
                            {
                                // Safe In-place Update
                                _context.Entry(existingMed).CurrentValues.SetValues(med);
                                batchMedIds.Add(existingMed.Id);
                            }
                            else
                            {
                                // New addition - MUST check for global collisions
                                if (batchMedIds.Contains(med.Id) || await _context.PrescriptionMedicines.AsNoTracking().AnyAsync(m => m.Id == med.Id))
                                {
                                    med.Id = Guid.NewGuid();
                                }
                                _context.PrescriptionMedicines.Add(med);
                                batchMedIds.Add(med.Id);
                            }
                        }

                        LogAudit(clinicId, "Prescription", rx.Id, "Update", userId);
                    }
                }
            }

            // 3. Process Doctor Profile
            if (payload.DoctorProfile != null)
            {
                var dp = payload.DoctorProfile;
                dp.ClinicId = clinicId; // Isolate
                
                var existingDp = await _context.DoctorProfiles.FirstOrDefaultAsync(x => x.ClinicId == clinicId);
                
                if (existingDp == null)
                {
                    dp.Id = 0; // Prevent explicit identity insertion error (0x80131904)
                    _context.DoctorProfiles.Add(dp);
                    LogAudit(clinicId, "DoctorProfile", Guid.NewGuid(), "Insert", userId);
                }
                else if (dp.UpdatedAt > existingDp.UpdatedAt)
                {
                    // Exclude ID from being overwritten
                    var oldId = existingDp.Id;
                    _context.Entry(existingDp).CurrentValues.SetValues(dp);
                    existingDp.Id = oldId;
                    LogAudit(clinicId, "DoctorProfile", Guid.NewGuid(), "Update", userId);
                }
            }

            // 4. Process Medical Guidelines & Clinical Intelligence (Shared Knowledge)
            if (payload.MedicalGuidelines != null)
            {
                foreach (var g in payload.MedicalGuidelines)
                {
                    var existing = await _context.MedicalGuidelines.FirstOrDefaultAsync(x => x.Id == g.Id);
                    if (existing == null) _context.MedicalGuidelines.Add(g);
                    else _context.Entry(existing).CurrentValues.SetValues(g);
                }
            }

            if (payload.DrugInteractions != null)
            {
                foreach (var di in payload.DrugInteractions)
                {
                    di.ClinicId = clinicId;
                    var existing = await _context.DrugInteractions.FirstOrDefaultAsync(x => x.Id == di.Id);
                    if (existing == null) _context.DrugInteractions.Add(di);
                    else _context.Entry(existing).CurrentValues.SetValues(di);
                }
            }


            await _context.SaveChangesAsync();
            await transaction.CommitAsync();
            
            return Ok(new { success = true, lastSync = DateTime.UtcNow });
        }
        catch (DbUpdateException dbEx)
        {
            await transaction.RollbackAsync();
            
            // Get the actual database error (e.g. Unique Constraint or FK violation)
            var innerMessage = dbEx.InnerException?.Message ?? dbEx.Message;
            if (dbEx.InnerException?.InnerException != null) 
                innerMessage = dbEx.InnerException.InnerException.Message;

            Console.WriteLine($"❌ SYNC PUSH ERROR (Clinic: {clinicId}): {innerMessage}");
            
            return BadRequest(new { success = false, error = $"Database Update Error: {innerMessage}" });
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            Console.WriteLine($"❌ SYNC GLOBAL ERROR: {ex.Message}");
            return BadRequest(new { success = false, error = ex.Message });
        }
    }

    /// <summary>
    /// Pull changes from Server to Local SQLite device for the specific Account
    /// Patients: ALWAYS full sync (lightweight, must reflect true clinic state)
    /// Prescriptions: Incremental (heavyweight, only changes since last sync)
    /// </summary>
    [HttpGet("pull")]
    public async Task<IActionResult> Pull([FromQuery] DateTime? lastSyncTime)
    {
        var sinceTime = lastSyncTime ?? DateTime.MinValue;
        var clinicId = GetCurrentClinicId();

        // 1. Fetch Prescriptions (Incremental: only those modified since last sync)
        //    Always include the linked patient, hence the sub-query isolation guard.
        var prescriptions = await _context.Prescriptions
.AsNoTracking()
             .Include(x => x.PrescriptionMedicines)
             .Include(x => x.VitalSign)
             .Where(pr => pr.LastModifiedAt > sinceTime
                       && _context.Patients.Any(p => p.Id == pr.PatientId && p.ClinicId == clinicId))
             .ToListAsync();

        // 2. Fetch ALL Patients for this clinic (FULL SYNC — always)
        //    Patient records are small (a few text fields). Incremental logic here causes
        //    silent data gaps on the mobile when patients have no recent activity.
        //    We always return the complete list so the mobile always mirrors the server state exactly.
        var patients = await _context.Patients
            .AsNoTracking()
            .Where(p => p.ClinicId == clinicId && !p.IsDeleted)
            .OrderBy(p => p.CreatedAt)
            .ToListAsync();

        var doctorProfile = await _context.DoctorProfiles
             .FirstOrDefaultAsync(dp => dp.ClinicId == clinicId);

        Console.WriteLine($"📦 PULL: Clinic={clinicId}, Since={sinceTime:yyyy-MM-dd HH:mm}, Patients={patients.Count} (full), Rx={prescriptions.Count} (delta)");

        return Ok(new SyncPullResponse
        {
            ServerTimestamp = DateTime.UtcNow,
            TotalPatientCount = patients.Count,
            Patients = patients,
            DoctorProfile = doctorProfile,
            MedicalGuidelines = await _context.MedicalGuidelines.Where(g => g.IsActive).ToListAsync(),
            DrugInteractions = await _context.DrugInteractions.Where(di => di.ClinicId == clinicId).ToListAsync(),
            MedicationTemplates = await _context.MedicationTemplates.Where(mt => mt.ClinicId == clinicId).ToListAsync()
        });

    }

    private void LogAudit(Guid clinicId, string type, Guid entityId, string op, string? userId)
    {
        _context.SyncAuditLogs.Add(new SyncAuditLog
        {
            Id = Guid.NewGuid(),
            ClinicId = clinicId,
            EntityType = type,
            EntityId = entityId,
            OperationType = op,
            Timestamp = DateTime.UtcNow,
            ChangedByUserId = userId
        });
    }
}

public class SyncPushPayload
{
    public List<Patient>? Patients { get; set; }
    public List<Prescription>? Prescriptions { get; set; }
    public DoctorProfile? DoctorProfile { get; set; }
    public List<MedicalGuideline>? MedicalGuidelines { get; set; }
    public List<DrugInteraction>? DrugInteractions { get; set; }
}


public class SyncPullResponse
{
    public DateTime ServerTimestamp { get; set; }
    public int TotalPatientCount { get; set; }       // Total patients on server — client uses this to detect gaps
    public List<Patient> Patients { get; set; } = new();
    public List<Prescription> Prescriptions { get; set; } = new();
    public DoctorProfile? DoctorProfile { get; set; }
    public List<MedicalGuideline> MedicalGuidelines { get; set; } = new();
    public List<DrugInteraction> DrugInteractions { get; set; } = new();
    public List<MedicationTemplate> MedicationTemplates { get; set; } = new();
}


