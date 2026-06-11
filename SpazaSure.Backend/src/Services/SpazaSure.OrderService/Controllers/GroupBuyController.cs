using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SpazaSure.Infrastructure.Data;
using SpazaSure.Shared.Models;
using System.Security.Claims;

namespace SpazaSure.OrderService.Controllers;

/// <summary>
/// Group Buy feature — allows shops to pool orders for bulk discounts.
/// Uses in-memory storage for now; will be backed by a GroupBuy table later.
/// </summary>
[ApiController]
[Route("api/shop/group-buy")]
[Authorize]
public class GroupBuyController(SpazaSureDbContext db) : ControllerBase
{
    private Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    // In-memory store (production: replace with DB table)
    private static readonly List<GroupBuyEntry> _groupBuys = [];
    private static readonly object _lock = new();

    /// <summary>
    /// Create a new group buy.
    /// </summary>
    [HttpPost("create")]
    public async Task<IActionResult> Create([FromBody] CreateGroupBuyRequest req)
    {
        var shop = await db.SpazaShops.FirstOrDefaultAsync(s => s.UserId == UserId);
        if (shop is null) return NotFound(ApiResponse.Fail("Shop not found."));

        if (string.IsNullOrWhiteSpace(req.Title))
            return BadRequest(ApiResponse.Fail("Title is required."));

        var entry = new GroupBuyEntry
        {
            Id = Guid.NewGuid(),
            Title = req.Title,
            InitiatorShopId = shop.Id,
            InitiatorShopName = shop.ShopName,
            MaxParticipants = req.MaxParticipants > 0 ? req.MaxParticipants : 10,
            ClosesAt = req.ClosesAt ?? DateTime.UtcNow.AddDays(3),
            CreatedAt = DateTime.UtcNow,
            Status = "open",
            Participants = [new GroupBuyParticipant { ShopId = shop.Id, ShopName = shop.ShopName, JoinedAt = DateTime.UtcNow }]
        };

        lock (_lock) { _groupBuys.Add(entry); }

        return Ok(ApiResponse<object>.Ok(MapEntry(entry)));
    }

    /// <summary>
    /// Get open group buys nearby (all open ones for now).
    /// </summary>
    [HttpGet("nearby")]
    public IActionResult GetNearby()
    {
        List<GroupBuyEntry> open;
        lock (_lock) { open = _groupBuys.Where(g => g.Status == "open" && g.ClosesAt > DateTime.UtcNow).ToList(); }

        return Ok(ApiResponse<object>.Ok(open.Select(MapEntry).ToList()));
    }

    /// <summary>
    /// Join an existing group buy.
    /// </summary>
    [HttpPost("{id:guid}/join")]
    public async Task<IActionResult> Join(Guid id)
    {
        var shop = await db.SpazaShops.FirstOrDefaultAsync(s => s.UserId == UserId);
        if (shop is null) return NotFound(ApiResponse.Fail("Shop not found."));

        lock (_lock)
        {
            var entry = _groupBuys.FirstOrDefault(g => g.Id == id);
            if (entry is null) return NotFound(ApiResponse.Fail("Group buy not found."));
            if (entry.Status != "open") return BadRequest(ApiResponse.Fail("This group buy is closed."));
            if (entry.Participants.Any(p => p.ShopId == shop.Id))
                return BadRequest(ApiResponse.Fail("You already joined this group."));
            if (entry.Participants.Count >= entry.MaxParticipants)
                return BadRequest(ApiResponse.Fail("Group is full."));

            entry.Participants.Add(new GroupBuyParticipant { ShopId = shop.Id, ShopName = shop.ShopName, JoinedAt = DateTime.UtcNow });

            // Auto-close if max reached
            if (entry.Participants.Count >= entry.MaxParticipants)
                entry.Status = "closed";

            return Ok(ApiResponse<object>.Ok(MapEntry(entry)));
        }
    }

    /// <summary>
    /// Get details of a specific group buy.
    /// </summary>
    [HttpGet("{id:guid}")]
    public IActionResult GetDetails(Guid id)
    {
        lock (_lock)
        {
            var entry = _groupBuys.FirstOrDefault(g => g.Id == id);
            if (entry is null) return NotFound(ApiResponse.Fail("Group buy not found."));
            return Ok(ApiResponse<object>.Ok(MapEntry(entry)));
        }
    }

    /// <summary>
    /// Get group buys the current shop is participating in.
    /// </summary>
    [HttpGet("mine")]
    public async Task<IActionResult> GetMine()
    {
        var shop = await db.SpazaShops.FirstOrDefaultAsync(s => s.UserId == UserId);
        if (shop is null) return NotFound(ApiResponse.Fail("Shop not found."));

        List<GroupBuyEntry> mine;
        lock (_lock) { mine = _groupBuys.Where(g => g.Participants.Any(p => p.ShopId == shop.Id)).ToList(); }

        return Ok(ApiResponse<object>.Ok(mine.Select(MapEntry).ToList()));
    }

    private static object MapEntry(GroupBuyEntry e) => new
    {
        id = e.Id,
        title = e.Title,
        status = e.Status,
        initiatorShopName = e.InitiatorShopName,
        participantCount = e.Participants.Count,
        maxParticipants = e.MaxParticipants,
        targetAmount = 0m,
        currentAmount = 0m,
        createdAt = e.CreatedAt,
        closesAt = e.ClosesAt,
        participants = e.Participants.Select(p => new { p.ShopName, p.JoinedAt })
    };
}

public record CreateGroupBuyRequest(string Title, int MaxParticipants, DateTime? ClosesAt, List<object>? Items);

// In-memory models (move to DB entities later)
public class GroupBuyEntry
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public Guid InitiatorShopId { get; set; }
    public string InitiatorShopName { get; set; } = string.Empty;
    public string Status { get; set; } = "open";
    public int MaxParticipants { get; set; } = 10;
    public DateTime CreatedAt { get; set; }
    public DateTime ClosesAt { get; set; }
    public List<GroupBuyParticipant> Participants { get; set; } = [];
}

public class GroupBuyParticipant
{
    public Guid ShopId { get; set; }
    public string ShopName { get; set; } = string.Empty;
    public DateTime JoinedAt { get; set; }
}
