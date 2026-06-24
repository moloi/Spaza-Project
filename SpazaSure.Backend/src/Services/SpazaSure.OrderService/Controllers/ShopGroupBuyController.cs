using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SpazaSure.Infrastructure.Data;
using SpazaSure.Infrastructure.Entities;
using SpazaSure.Shared.Models;
using System.Security.Claims;

namespace SpazaSure.OrderService.Controllers;

[ApiController]
[Route("api/shop/group-buy")]
[Authorize(Roles = "spaza_owner")]
public class ShopGroupBuyController(SpazaSureDbContext db) : ControllerBase
{
    private Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    /// <summary>List all active group buys available to join.</summary>
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] string status = "active")
    {
        var query = db.GroupBuys
            .Include(g => g.Product)
            .Include(g => g.Supplier)
            .Include(g => g.CreatedByShop)
            .Include(g => g.Participants).ThenInclude(p => p.Shop)
            .AsQueryable();

        if (status == "active")
            query = query.Where(g => g.Status == "active" && g.ExpiresAt > DateTime.UtcNow);
        else if (status == "my")
        {
            var shop = await db.SpazaShops.FirstOrDefaultAsync(s => s.UserId == UserId);
            if (shop == null) return NotFound(ApiResponse.Fail("Shop not found."));
            query = query.Where(g => g.Participants.Any(p => p.ShopId == shop.Id));
        }
        else
            query = query.Where(g => g.Status == status);

        var items = await query.OrderByDescending(g => g.CreatedAt).Take(50).ToListAsync();

        var result = items.Select(g => new {
            g.Id, g.Title, g.Description, g.TargetQty, g.CurrentQty,
            g.OriginalPrice, g.DiscountPrice, g.DiscountPct,
            g.ExpiresAt, g.Status, g.CreatedAt,
            ProductId = g.ProductId,
            ProductName = g.Product.Name,
            ProductImages = g.Product.Images,
            SupplierId = g.SupplierId,
            SupplierName = g.Supplier.CompanyName,
            CreatedByShopName = g.CreatedByShop.ShopName,
            ParticipantCount = g.Participants.Count(p => p.Status == "joined"),
            Progress = g.TargetQty > 0 ? Math.Round((double)g.CurrentQty / g.TargetQty * 100, 1) : 0,
            Participants = g.Participants.Where(p => p.Status == "joined").Select(p => new {
                p.Id, p.ShopId, ShopName = p.Shop.ShopName, p.Quantity, p.CreatedAt
            }),
        });

        return Ok(ApiResponse<object>.Ok(result));
    }

    /// <summary>Create a new group buy for a product.</summary>
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateGroupBuyRequest req)
    {
        var shop = await db.SpazaShops.FirstOrDefaultAsync(s => s.UserId == UserId);
        if (shop == null) return NotFound(ApiResponse.Fail("Shop not found."));

        var product = await db.Products.Include(p => p.Supplier).FirstOrDefaultAsync(p => p.Id == req.ProductId);
        if (product == null) return NotFound(ApiResponse.Fail("Product not found."));

        var discountPct = req.DiscountPct > 0 ? req.DiscountPct : 15;
        var discountPrice = Math.Round(product.Price * (1 - (decimal)discountPct / 100), 2);

        var groupBuy = new GroupBuy
        {
            Title = req.Title ?? $"Group Buy: {product.Name}",
            Description = req.Description ?? $"Pool orders for {product.Name} and save {discountPct}%!",
            ProductId = product.Id,
            SupplierId = product.SupplierId,
            TargetQty = req.TargetQty > 0 ? req.TargetQty : 50,
            CurrentQty = req.MyQty,
            OriginalPrice = product.Price,
            DiscountPrice = discountPrice,
            DiscountPct = discountPct,
            ExpiresAt = DateTime.UtcNow.AddDays(req.DurationDays > 0 ? req.DurationDays : 7),
            Status = "active",
            CreatedByShopId = shop.Id,
        };

        db.GroupBuys.Add(groupBuy);

        // Add creator as first participant
        var participant = new GroupBuyParticipant
        {
            GroupBuyId = groupBuy.Id,
            ShopId = shop.Id,
            Quantity = req.MyQty > 0 ? req.MyQty : product.MinOrderQty,
            Status = "joined",
        };
        db.GroupBuyParticipants.Add(participant);

        await db.SaveChangesAsync();

        return Ok(ApiResponse<object>.Ok(new { groupBuy.Id, Message = "Group buy created successfully!" }));
    }

    /// <summary>Join an existing group buy.</summary>
    [HttpPost("{id:guid}/join")]
    public async Task<IActionResult> Join(Guid id, [FromBody] JoinGroupBuyRequest req)
    {
        var shop = await db.SpazaShops.FirstOrDefaultAsync(s => s.UserId == UserId);
        if (shop == null) return NotFound(ApiResponse.Fail("Shop not found."));

        var groupBuy = await db.GroupBuys.Include(g => g.Participants).FirstOrDefaultAsync(g => g.Id == id);
        if (groupBuy == null) return NotFound(ApiResponse.Fail("Group buy not found."));
        if (groupBuy.Status != "active") return BadRequest(ApiResponse.Fail("This group buy is no longer active."));
        if (groupBuy.ExpiresAt < DateTime.UtcNow) return BadRequest(ApiResponse.Fail("This group buy has expired."));

        // Check if already joined
        if (groupBuy.Participants.Any(p => p.ShopId == shop.Id && p.Status == "joined"))
            return BadRequest(ApiResponse.Fail("You have already joined this group buy."));

        var qty = req.Quantity > 0 ? req.Quantity : 1;
        var participant = new GroupBuyParticipant
        {
            GroupBuyId = groupBuy.Id,
            ShopId = shop.Id,
            Quantity = qty,
            Status = "joined",
        };
        db.GroupBuyParticipants.Add(participant);

        groupBuy.CurrentQty += qty;

        // Check if target reached
        if (groupBuy.CurrentQty >= groupBuy.TargetQty)
            groupBuy.Status = "completed";

        await db.SaveChangesAsync();

        return Ok(ApiResponse<object>.Ok(new { Message = "You have joined the group buy!", groupBuy.CurrentQty, groupBuy.TargetQty }));
    }

    /// <summary>Leave a group buy.</summary>
    [HttpPost("{id:guid}/leave")]
    public async Task<IActionResult> Leave(Guid id)
    {
        var shop = await db.SpazaShops.FirstOrDefaultAsync(s => s.UserId == UserId);
        if (shop == null) return NotFound(ApiResponse.Fail("Shop not found."));

        var participant = await db.GroupBuyParticipants
            .FirstOrDefaultAsync(p => p.GroupBuyId == id && p.ShopId == shop.Id && p.Status == "joined");
        if (participant == null) return NotFound(ApiResponse.Fail("You are not a participant in this group buy."));

        participant.Status = "cancelled";

        var groupBuy = await db.GroupBuys.FindAsync(id);
        if (groupBuy != null) groupBuy.CurrentQty -= participant.Quantity;

        await db.SaveChangesAsync();

        return Ok(ApiResponse<object>.Ok(new { Message = "You have left the group buy." }));
    }
}

/// <summary>Supplier-facing group buy endpoints.</summary>
[ApiController]
[Route("api/supplier/group-buy")]
[Authorize(Roles = "supplier")]
public class SupplierGroupBuyController(SpazaSureDbContext db) : ControllerBase
{
    private Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    /// <summary>List group buys for this supplier's products.</summary>
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] string status = "all")
    {
        var supplier = await db.Suppliers.FirstOrDefaultAsync(s => s.UserId == UserId);
        if (supplier == null) return NotFound(ApiResponse.Fail("Supplier not found."));

        var query = db.GroupBuys
            .Include(g => g.Product)
            .Include(g => g.CreatedByShop)
            .Include(g => g.Participants).ThenInclude(p => p.Shop)
            .Where(g => g.SupplierId == supplier.Id);

        if (status != "all")
            query = query.Where(g => g.Status == status);

        var items = await query.OrderByDescending(g => g.CreatedAt).Take(50).ToListAsync();

        var result = items.Select(g => new {
            g.Id, g.Title, g.Description, g.TargetQty, g.CurrentQty,
            g.OriginalPrice, g.DiscountPrice, g.DiscountPct,
            g.ExpiresAt, g.Status, g.CreatedAt,
            ProductId = g.ProductId,
            ProductName = g.Product.Name,
            CreatedByShopName = g.CreatedByShop.ShopName,
            ParticipantCount = g.Participants.Count(p => p.Status == "joined"),
            Progress = g.TargetQty > 0 ? Math.Round((double)g.CurrentQty / g.TargetQty * 100, 1) : 0,
            Participants = g.Participants.Where(p => p.Status == "joined").Select(p => new {
                p.Id, p.ShopId, ShopName = p.Shop.ShopName, p.Quantity, p.CreatedAt
            }),
        });

        return Ok(ApiResponse<object>.Ok(result));
    }

    /// <summary>Approve/confirm a completed group buy (creates orders).</summary>
    [HttpPost("{id:guid}/approve")]
    public async Task<IActionResult> Approve(Guid id)
    {
        var supplier = await db.Suppliers.FirstOrDefaultAsync(s => s.UserId == UserId);
        if (supplier == null) return NotFound(ApiResponse.Fail("Supplier not found."));

        var groupBuy = await db.GroupBuys
            .Include(g => g.Participants).ThenInclude(p => p.Shop)
            .Include(g => g.Product)
            .FirstOrDefaultAsync(g => g.Id == id && g.SupplierId == supplier.Id);
        if (groupBuy == null) return NotFound(ApiResponse.Fail("Group buy not found."));

        // Create individual orders for each participant
        var orderCount = 0;
        foreach (var p in groupBuy.Participants.Where(p => p.Status == "joined"))
        {
            var orderNum = $"SPZ-GB-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString()[..4].ToUpper()}";
            var lineTotal = groupBuy.DiscountPrice * p.Quantity;
            var order = new Order
            {
                OrderNumber = orderNum,
                ShopId = p.ShopId,
                SupplierId = supplier.Id,
                GroupBuyId = groupBuy.Id,
                Status = "confirmed",
                DeliveryType = "standard",
                Subtotal = lineTotal,
                DeliveryFee = 0,
                PlatformCommission = 0,
                TotalAmount = lineTotal,
                Notes = $"Group Buy: {groupBuy.Title}",
            };
            db.Orders.Add(order);

            var item = new OrderItem
            {
                OrderId = order.Id,
                ProductId = groupBuy.ProductId,
                Quantity = p.Quantity,
                UnitPrice = groupBuy.DiscountPrice,
                LineTotal = lineTotal,
            };
            db.OrderItems.Add(item);

            p.Status = "confirmed";
            orderCount++;
        }

        groupBuy.Status = "completed";
        await db.SaveChangesAsync();

        return Ok(ApiResponse<object>.Ok(new { Message = $"Group buy approved! {orderCount} orders created.", OrderCount = orderCount }));
    }
}

// ── Request Models ────────────────────────────────────────────────────────────

public record CreateGroupBuyRequest
{
    public Guid ProductId { get; init; }
    public string? Title { get; init; }
    public string? Description { get; init; }
    public int TargetQty { get; init; }
    public int MyQty { get; init; }
    public int DiscountPct { get; init; }
    public int DurationDays { get; init; }
}

public record JoinGroupBuyRequest
{
    public int Quantity { get; init; }
}
