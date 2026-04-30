using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace Rachita.Api.DTOs;

public class CheckInteractionsRequest
{
    public List<string> Medicines { get; set; } = new();
}

