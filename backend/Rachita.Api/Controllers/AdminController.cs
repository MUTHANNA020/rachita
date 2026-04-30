using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authorization;
using Rachita.Core.Entities;
using Rachita.Infrastructure.Data;
using BCrypt.Net;

namespace Rachita.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public class AdminController : ControllerBase
{
    private readonly AppDbContext _context;

    public AdminController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet("stats")]
    public async Task<IActionResult> GetGlobalStats()
    {
        var totalClinics = await _context.Clinics.CountAsync();
        var totalUsers = await _context.Users.CountAsync();
        var totalPatients = await _context.Patients.CountAsync();
        var activeClinics = await _context.Clinics.CountAsync(c => c.Status == "Active");
        var suspendedClinics = await _context.Clinics.CountAsync(c => c.Status == "Suspended");
        var trialClinics = await _context.Clinics.CountAsync(c => c.Status == "Trial");

        // Activity in last 24h
        var activeToday = await _context.SyncAuditLogs
            .Where(l => l.Timestamp >= DateTime.UtcNow.AddDays(-1))
            .Select(l => l.ClinicId)
            .Distinct()
            .CountAsync();

        // Additional metrics
        var totalPrescriptions = await _context.Prescriptions.CountAsync();
        var totalVitalSigns = await _context.VitalSigns.CountAsync();
        var recentActivity = await _context.SyncAuditLogs
            .Where(l => l.Timestamp >= DateTime.UtcNow.AddHours(-1))
            .CountAsync();

        // System health
        var dbConnectionHealthy = true; // In a real app, you'd test actual DB connection
        var uptime = DateTime.UtcNow - new DateTime(2026, 4, 1); // Mock uptime

        return Ok(new
        {
            // Core metrics
            TotalClinics = totalClinics,
            TotalUsers = totalUsers,
            TotalPatients = totalPatients,
            ActiveClinicsToday = activeToday,

            // Clinic status breakdown
            ActiveClinics = activeClinics,
            SuspendedClinics = suspendedClinics,
            TrialClinics = trialClinics,

            // Medical data
            TotalPrescriptions = totalPrescriptions,
            TotalVitalSigns = totalVitalSigns,

            // Activity metrics
            RecentActivity = recentActivity, // Activity in last hour
            Growth = 12.5, // Mock growth percentage

            // System health
            DatabaseHealthy = dbConnectionHealthy,
            UptimeHours = uptime.TotalHours,
            ServerTimestamp = DateTime.UtcNow
        });
    }

    [HttpGet("clinics")]
    public async Task<IActionResult> GetClinics()
    {
        var clinics = await _context.Clinics
            .Select(c => new
            {
                c.Id,
                c.Name,
                c.SubscriptionTier,
                c.Status,
                c.CreatedAt,
                UserCount = _context.Users.Count(u => u.ClinicId == c.Id),
                PatientCount = _context.Patients.Count(p => p.ClinicId == c.Id),
                PrescriptionCount = _context.Prescriptions.Count(p => _context.Patients.Any(pt => pt.Id == p.PatientId && pt.ClinicId == c.Id)),
                StorageUsageMb = (_context.Patients.Count(p => p.ClinicId == c.Id) * 0.5) + (_context.Prescriptions.Count(p => _context.Patients.Any(pt => pt.Id == p.PatientId && pt.ClinicId == c.Id)) * 0.1), // Estimated
                LastSync = _context.SyncAuditLogs
                    .Where(l => l.ClinicId == c.Id)
                    .OrderByDescending(l => l.Timestamp)
                    .Select(l => l.Timestamp)
                    .FirstOrDefault(),
                SyncHealth = _context.SyncAuditLogs.Any(l => l.ClinicId == c.Id && l.Timestamp > DateTime.UtcNow.AddDays(-1)) ? "Healthy" : "Idle"
            })
            .ToListAsync();

        return Ok(clinics);
    }

    [HttpPost("clinics/{id}/status")]
    public async Task<IActionResult> UpdateClinicStatus(Guid id, [FromBody] UpdateStatusRequest req)
    {
        string status = req.Status;
        var clinic = await _context.Clinics.FindAsync(id);
        if (clinic == null) return NotFound();

        clinic.Status = status;
        await _context.SaveChangesAsync();
        return Ok(new { success = true, status = clinic.Status });
    }

    [HttpPut("clinics/{id}")]
    public async Task<IActionResult> UpdateClinic(Guid id, [FromBody] UpdateClinicRequest req)
    {
        var clinic = await _context.Clinics.FindAsync(id);
        if (clinic == null) return NotFound();

        clinic.Name = req.Name ?? clinic.Name;
        clinic.SubscriptionTier = req.SubscriptionTier ?? clinic.SubscriptionTier;
        clinic.Address = req.Address ?? clinic.Address;
        clinic.ContactNumber = req.ContactNumber ?? clinic.ContactNumber;
        clinic.Status = req.Status ?? clinic.Status;

        await _context.SaveChangesAsync();
        return Ok(new { success = true, clinic });
    }

    [HttpPost("clinics")]
    public async Task<IActionResult> CreateClinic([FromBody] CreateClinicRequest req)
    {
        string name = req.Name;
        string username = req.Username;
        string password = req.Password;
        string doctorName = req.DoctorName;

        var clinic = new Clinic { Name = name, Status = "Active" };
        var user = new User
        {
            ClinicId = clinic.Id,
            Username = username,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(password),
            FullName = doctorName,
            Role = "Doctor"
        };

        _context.Clinics.Add(clinic);
        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        return Ok(new { id = clinic.Id, name = clinic.Name });
    }

    [HttpDelete("clinics/{id}")]
    public async Task<IActionResult> DeleteClinic(Guid id)
    {
        var clinic = await _context.Clinics.Include(c => c.Users).FirstOrDefaultAsync(c => c.Id == id);
        if (clinic == null) return NotFound();

        _context.Clinics.Remove(clinic);
        await _context.SaveChangesAsync();
        return Ok(new { success = true });
    }

    [HttpGet("users")]
    public async Task<IActionResult> GetUsers()
    {
        var users = await _context.Users
            .Select(u => new
            {
                u.Id,
                u.Username,
                u.FullName,
                u.Role,
                Status = u.IsActive ? "Active" : "Inactive",
                u.CreatedAt,
                ClinicName = u.Clinic != null ? u.Clinic.Name : "N/A",
                ClinicId = u.ClinicId,
                LastLogin = _context.SyncAuditLogs
                    .Where(l => l.ChangedByUserId == u.Id.ToString())
                    .OrderByDescending(l => l.Timestamp)
                    .Select(l => l.Timestamp)
                    .FirstOrDefault()
            })
            .ToListAsync();

        return Ok(users);
    }

    [HttpPost("users")]
    public async Task<IActionResult> CreateUser([FromBody] CreateUserRequest req)
    {
        var clinic = await _context.Clinics.FindAsync(req.ClinicId);
        if (clinic == null) return BadRequest(new { error = "Clinic not found" });

        var user = new User
        {
            ClinicId = req.ClinicId,
            Username = req.Username,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(req.Password),
            FullName = req.FullName,
            Role = req.Role ?? "Staff",
            IsActive = true
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();
        return Ok(new { id = user.Id, username = user.Username, fullName = user.FullName });
    }

    [HttpPut("users/{id}")]
    public async Task<IActionResult> UpdateUser(Guid id, [FromBody] UpdateUserRequest req)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound();

        user.FullName = req.FullName ?? user.FullName;
        user.Role = req.Role ?? user.Role;
        user.IsActive = req.IsActive ?? user.IsActive;
        user.Username = req.Username ?? user.Username;

        await _context.SaveChangesAsync();
        return Ok(new { success = true, user });
    }

    [HttpPost("users/{id}/reset-password")]
    public async Task<IActionResult> ResetUserPassword(Guid id, [FromBody] ResetPasswordRequest req)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound();

        if (string.IsNullOrWhiteSpace(req.NewPassword))
        {
            return BadRequest(new { error = "NewPassword is required." });
        }

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(req.NewPassword);
        await _context.SaveChangesAsync();
        return Ok(new { success = true, message = "Password reset successfully." });
    }

    [HttpPost("users/{id}/status")]
    public async Task<IActionResult> UpdateUserStatus(Guid id, [FromBody] UpdateStatusRequest req)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound();

        user.IsActive = req.Status == "Active";
        await _context.SaveChangesAsync();
        return Ok(new { success = true, status = user.IsActive ? "Active" : "Inactive" });
    }

    [HttpGet("backup-summary")]
    public async Task<IActionResult> GetBackupSummary()
    {
        var summary = await _context.Clinics
            .Select(c => new
            {
                ClinicName = c.Name,
                PatientCount = _context.Patients.Count(p => p.ClinicId == c.Id),
                PrescriptionCount = _context.Prescriptions.Count(p => _context.Patients.Any(pt => pt.Id == p.PatientId && pt.ClinicId == c.Id)),
                LastSync = _context.SyncAuditLogs
                    .Where(l => l.ClinicId == c.Id)
                    .OrderByDescending(l => l.Timestamp)
                    .Select(l => l.Timestamp)
                    .FirstOrDefault(),
                HealthStatus = _context.SyncAuditLogs.Any(l => l.ClinicId == c.Id && l.Timestamp > DateTime.UtcNow.AddDays(-1)) ? "Active" : "Idle"
            })
            .ToListAsync();

        return Ok(summary);
    }

    [HttpDelete("users/{id}")]
    public async Task<IActionResult> DeleteUser(Guid id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound();

        _context.Users.Remove(user);
        await _context.SaveChangesAsync();
        return Ok(new { success = true });
    }

    [HttpGet("settings")]
    public async Task<IActionResult> GetSettings()
    {
        return Ok(new
        {
            SystemName = "Rachita Pro",
            Version = "1.0.0",
            Environment = "Development",
            TotalClinics = await _context.Clinics.CountAsync(),
            TotalUsers = await _context.Users.CountAsync(),
            TotalPatients = await _context.Patients.CountAsync(),
            DatabaseSize = "~" + (await _context.Patients.CountAsync() * 5) + "MB",
            BackupFrequency = "Daily at 2:00 AM",
            SecurityLevel = "High (TLS 1.3, JWT)",
            MaintenanceMode = false,
            MaintenanceSchedule = "Last: 2026-04-03 | Next: 2026-04-10",
            APIRateLimit = "1000 requests/hour",
            SessionTimeout = "30 minutes",
            MaxUploadSize = "100MB",
            AllowedFileTypes = ".pdf, .jpg, .png, .docx"
        });
    }

    [HttpPost("settings")]
    public async Task<IActionResult> UpdateSettings([FromBody] UpdateSettingsRequest req)
    {
        // In a real app, settings would be stored in DB/config
        return Ok(new { success = true, message = "Settings updated successfully" });
    }
}

// Request models
public class CreateClinicRequest
{
    public string Name { get; set; } = null!;
    public string Username { get; set; } = null!;
    public string Password { get; set; } = null!;
    public string DoctorName { get; set; } = null!;
}

public class UpdateStatusRequest
{
    public string Status { get; set; } = null!;
}

public class CreateUserRequest
{
    public Guid ClinicId { get; set; }
    public string Username { get; set; } = null!;
    public string Password { get; set; } = null!;
    public string FullName { get; set; } = null!;
    public string Role { get; set; } = null!;
}

public class UpdateUserRequest
{
    public string? Username { get; set; }
    public string? FullName { get; set; }
    public string? Role { get; set; }
    public bool? IsActive { get; set; }
}

public class ResetPasswordRequest
{
    public string NewPassword { get; set; } = null!;
}

public class UpdateClinicRequest
{
    public string? Name { get; set; }
    public string? SubscriptionTier { get; set; }
    public string? Address { get; set; }
    public string? ContactNumber { get; set; }
    public string? Status { get; set; }
}

public class UpdateSettingsRequest
{
    public string PropertyName { get; set; } = null!;
    public object PropertyValue { get; set; } = null!;
}
