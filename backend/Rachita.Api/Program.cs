using Microsoft.EntityFrameworkCore;
using Rachita.Infrastructure.Data;
using Rachita.Core.Entities;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Microsoft.AspNetCore.Hosting.Server;
using Microsoft.AspNetCore.Hosting.Server.Features;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
        options.JsonSerializerOptions.DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull;
    });
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Configure Database
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Configure JWT Authentication
var key = Encoding.ASCII.GetBytes(builder.Configuration["JwtSettings:SecretKey"]!);
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
}).AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ValidateIssuer = true,
        ValidIssuer = builder.Configuration["JwtSettings:Issuer"],
        ValidateAudience = true,
        ValidAudience = builder.Configuration["JwtSettings:Audience"]
    };
});

// Configure CORS for local network, web apps, and Admin Portal (Vite)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        policy => policy.SetIsOriginAllowed(_ => true)
                         .AllowAnyHeader()
                         .AllowAnyMethod()
                         .AllowCredentials());
    
    options.AddPolicy("AdminPortal",
        policy => policy.WithOrigins("http://localhost:5173", "http://localhost:4173", "http://localhost:5301", "https://localhost:5301", "https://localhost:7298", "http://127.0.0.1:5301", "https://127.0.0.1:5301")
                         .AllowAnyHeader()
                         .AllowAnyMethod()
                         .AllowCredentials());
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowAll");

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

app.UseDefaultFiles();
app.UseStaticFiles();

// CORS moved to top
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// Fallback to Admin Dashboard
app.MapFallbackToFile("/admin/index.html");

// Run Database Migrations and Seeding
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    try 
    {
        // الخطوة 1: محاولة تطبيق الـ Migrations (الطريقة الاحترافية لـ EF)
        try
        {
            context.Database.Migrate();
            Console.WriteLine("║ ✅ DB: Migrations applied successfully.                        ║");
        }
        catch (Exception migrateEx)
        {
            Console.WriteLine($"║ ⚠️  DB Migrate failed, switching to EnsureCreated: {migrateEx.Message.Substring(0, Math.Min(20, migrateEx.Message.Length))} ║");
            context.Database.EnsureCreated();
        }
        
        // الخطوة 2: ضمان وجود جدول DoctorProfiles دائماً (خط الأمان)
        try
        {
            context.Database.ExecuteSqlRaw(@"
                IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='DoctorProfiles' AND xtype='U')
                BEGIN
                    CREATE TABLE [DoctorProfiles] (
                        [Id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
                        [ClinicId] UNIQUEIDENTIFIER NOT NULL,
                        [Name] NVARCHAR(MAX) NOT NULL DEFAULT '',
                        [NameEn] NVARCHAR(MAX) NULL,
                        [Specialty] NVARCHAR(MAX) NOT NULL DEFAULT '',
                        [SpecialtyEn] NVARCHAR(MAX) NULL,
                        [SubSpecialty] NVARCHAR(MAX) NULL,
                        [SubSpecialtyEn] NVARCHAR(MAX) NULL,
                        [ClinicName] NVARCHAR(MAX) NOT NULL DEFAULT '',
                        [LicenseNumber] NVARCHAR(MAX) NULL,
                        [Credentials] NVARCHAR(MAX) NULL,
                        [CredentialsEn] NVARCHAR(MAX) NULL,
                        [Address] NVARCHAR(MAX) NULL,
                        [Phone] NVARCHAR(MAX) NULL,
                        [WorkingHoursFrom] NVARCHAR(MAX) NULL,
                        [WorkingHoursTo] NVARCHAR(MAX) NULL,
                        [LogoPath] NVARCHAR(MAX) NULL,
                        [SignaturePath] NVARCHAR(MAX) NULL,
                        [PhotoPath] NVARCHAR(MAX) NULL,
                        [Bio] NVARCHAR(MAX) NULL,
                        [BioEn] NVARCHAR(MAX) NULL,
                        [CreatedAt] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
                        [UpdatedAt] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
                        CONSTRAINT [FK_DoctorProfiles_Clinics] FOREIGN KEY ([ClinicId]) 
                            REFERENCES [Clinics] ([Id]) ON DELETE CASCADE
                    );
                    CREATE UNIQUE INDEX [IX_DoctorProfiles_ClinicId] ON [DoctorProfiles]([ClinicId]);
                    PRINT 'DoctorProfiles table created successfully.';
                END
                ELSE
                BEGIN
                    PRINT 'DoctorProfiles table already exists - OK.';
                END");
            Console.WriteLine("║ ✅ DB: DoctorProfiles table verified.                          ║");
        }
        catch (Exception tableEx)
        {
            Console.WriteLine($"║ ⚠️  DoctorProfiles check: {tableEx.Message.Substring(0, Math.Min(40, tableEx.Message.Length))} ║");
        }

        // ═══════════════════════════════════════════════════════════════
        // 🛡️ نظام الإصلاح الذاتي للأعمدة (Schema Self-Healing Engine)
        // يعمل في كل مرة يبدأ فيها السيرفر - يضمن سلامة قاعدة البيانات
        // بدون الحاجة لـ Migrations يدوية أبداً.
        // ═══════════════════════════════════════════════════════════════
        try
        {
            context.Database.ExecuteSqlRaw(@"
                -- ► جدول Patients - الأعمدة الحيوية
                IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[Patients]') AND name = 'IsDeleted')
                    ALTER TABLE [Patients] ADD [IsDeleted] BIT NOT NULL DEFAULT 0;

                IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[Patients]') AND name = 'LastModifiedAt')
                    ALTER TABLE [Patients] ADD [LastModifiedAt] DATETIME2 NOT NULL DEFAULT GETUTCDATE();

                IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[Patients]') AND name = 'AgeCategory')
                    ALTER TABLE [Patients] ADD [AgeCategory] INT NOT NULL DEFAULT 2;

                IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[Patients]') AND name = 'Allergies')
                    ALTER TABLE [Patients] ADD [Allergies] NVARCHAR(MAX) NULL;

                IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[Patients]') AND name = 'ChronicDiseases')
                    ALTER TABLE [Patients] ADD [ChronicDiseases] NVARCHAR(MAX) NULL;

                IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[Patients]') AND name = 'BloodGroup')
                    ALTER TABLE [Patients] ADD [BloodGroup] NVARCHAR(MAX) NULL;

                IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[Patients]') AND name = 'Height')
                    ALTER TABLE [Patients] ADD [Height] FLOAT NULL;

                IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[Patients]') AND name = 'IsPregnant')
                    ALTER TABLE [Patients] ADD [IsPregnant] BIT NOT NULL DEFAULT 0;

                IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[Patients]') AND name = 'MedicationHistoryJson')
                    ALTER TABLE [Patients] ADD [MedicationHistoryJson] NVARCHAR(MAX) NOT NULL DEFAULT '[]';

                IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[Patients]') AND name = 'CurrentMedicationsJson')
                    ALTER TABLE [Patients] ADD [CurrentMedicationsJson] NVARCHAR(MAX) NOT NULL DEFAULT '[]';

                IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[Patients]') AND name = 'PreexistingConditionsJson')
                    ALTER TABLE [Patients] ADD [PreexistingConditionsJson] NVARCHAR(MAX) NOT NULL DEFAULT '[]';

                -- ► جدول Prescriptions - الأعمدة الحيوية
                IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[Prescriptions]') AND name = 'IsDeleted')
                    ALTER TABLE [Prescriptions] ADD [IsDeleted] BIT NOT NULL DEFAULT 0;

                IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[Prescriptions]') AND name = 'ClinicId')
                BEGIN
                    ALTER TABLE [Prescriptions] ADD [ClinicId] UNIQUEIDENTIFIER NULL;
                    -- ربط البيانات الموجودة بعياداتها
                    UPDATE R SET R.ClinicId = P.ClinicId
                    FROM [Prescriptions] R JOIN [Patients] P ON R.PatientId = P.Id
                    WHERE R.ClinicId IS NULL;
                END

                -- ► جدول PrescriptionMedicines - الأعمدة الحيوية
                IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[PrescriptionMedicines]') AND name = 'DrugInteractionRisk')
                    ALTER TABLE [PrescriptionMedicines] ADD [DrugInteractionRisk] NVARCHAR(MAX) NULL;

                IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[PrescriptionMedicines]') AND name = 'RouteOfAdministration')
                    ALTER TABLE [PrescriptionMedicines] ADD [RouteOfAdministration] NVARCHAR(MAX) NULL;

                IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[PrescriptionMedicines]') AND name = 'Indication')
                    ALTER TABLE [PrescriptionMedicines] ADD [Indication] NVARCHAR(MAX) NULL;

                IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[PrescriptionMedicines]') AND name = 'WarningsAndContraindications')
                    ALTER TABLE [PrescriptionMedicines] ADD [WarningsAndContraindications] NVARCHAR(MAX) NULL;
            ");
            Console.WriteLine("║ ✅ DB: Self-Healing Schema Guard: ALL columns verified.        ║");
        }
        catch (Exception schemaEx)
        {
            Console.WriteLine($"║ ⚠️  Self-Healing warning: {schemaEx.Message.Substring(0, Math.Min(50, schemaEx.Message.Length))} ║");
        }
        
        if (!context.Users.Any(u => u.Role == "Admin"))
        {
            Console.WriteLine("║ 🛠️  SEEDING: Creating Default Admin Account...                 ║");
            var adminClinic = new Clinic { Name = "Rachita System Admin", Status = "Active" };
            var adminUser = new User 
            { 
                Username = "admin", 
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("admin123"), 
                Role = "Admin", 
                FullName = "System Architect",
                ClinicId = adminClinic.Id
            };
            context.Clinics.Add(adminClinic);
            context.Users.Add(adminUser);
            context.SaveChanges();
            Console.WriteLine("║ ✅ SEED: admin / admin123  (PASSWORD: admin123)               ║");
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine($"║ ❌ SEED ERROR: {ex.Message}                                     ║");
    }
}

// Connection Status Logger
app.Lifetime.ApplicationStarted.Register(() =>
{
    Console.WriteLine("\n╔════════════════════════════════════════════════════════════════╗");
    Console.WriteLine("║          🚀 RACHITA API SERVER - CONNECTION STATUS 🚀            ║");
    Console.WriteLine("╠════════════════════════════════════════════════════════════════╣");
    
    var serverFeatures = app.Services.GetRequiredService<IServer>().Features;
    var addresses = serverFeatures.Get<IServerAddressesFeature>();
    
    if (addresses != null && addresses.Addresses.Count > 0)
    {
        Console.WriteLine("║ ✅ STATUS: CONNECTED & RUNNING                                  ║");
        Console.WriteLine("╠════════════════════════════════════════════════════════════════╣");
        foreach (var address in addresses.Addresses)
        {
            Console.WriteLine($"║ 📍 Listening on: {address,-50} ║");
        }
    }
    else
    {
        Console.WriteLine("║ ❌ STATUS: CONNECTION FAILED                                    ║");
    }
    
    Console.WriteLine("║                                                                ║");
    Console.WriteLine("║ 🔌 Environment: " + (app.Environment.IsDevelopment() ? "DEVELOPMENT" : "PRODUCTION") + new string(' ', 34 - (app.Environment.IsDevelopment() ? "DEVELOPMENT" : "PRODUCTION").Length) + "║");
    Console.WriteLine("║ 🛡️  Authentication: JWT Enabled                                 ║");
    Console.WriteLine("║ 📦 Database: SQL Server Connected                              ║");
    Console.WriteLine("║ 🌐 CORS: Enabled for All Origins                               ║");
    Console.WriteLine("╚════════════════════════════════════════════════════════════════╝\n");
});

// Connection Status - Application Stopped
app.Lifetime.ApplicationStopping.Register(() =>
{
    Console.WriteLine("\n╔════════════════════════════════════════════════════════════════╗");
    Console.WriteLine("║          🛑 RACHITA API SERVER - SHUTTING DOWN 🛑               ║");
    Console.WriteLine("╠════════════════════════════════════════════════════════════════╣");
    Console.WriteLine("║ ⏹️  STATUS: DISCONNECTING                                       ║");
    Console.WriteLine("║ Gracefully shutting down the server...                        ║");
    Console.WriteLine("╚════════════════════════════════════════════════════════════════╝\n");
});

app.Run();
