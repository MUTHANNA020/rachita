using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace Rachita.Api.DTOs;

public class CreateTemplateRequest
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Specialty { get; set; }
    public List<object> Medicines { get; set; } = new();
}

