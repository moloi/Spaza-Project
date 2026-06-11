using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SpazaSure.Infrastructure.Data;
using SpazaSure.Infrastructure.Entities;
using SpazaSure.Shared.Models;
using System.Security.Claims;

namespace SpazaSure.OrderService.Controllers;

[ApiController]
[Route("api/shop/orders")]
[Authorize]
public class ShopOrdersController(SpazaSureDbContext db) : ControllerBase
{
    private Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    /// <summary>
    /// List orders for the current shop.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] int page = 1, [FromQuery] int pageSize = 20,
        [FromQuery] string? status = null)
    {
        var shop = await db.SpazaShops.FirstOrDefaultAsync(s => s.UserId == UserId);
        if (shop is null) return NotFound(ApiResponse.Fail("Shop not found."));

        var query = db.Orders
            .Include(o => o.Supplier)
            .Include(o => o.Items).ThenInclude(i => i.Product)
            .Where(o => o.ShopId == shop.Id);

        if (!string.IsNullOrEmpty(status))
            query = query.Where(o => o.Status == status);

        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(o => o.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(o => new
            {
                o.Id, o.OrderNumber, o.Status, o.TotalAmount,
                o.Subtotal, o.DeliveryFee, o.PlatformCommission,
                o.DeliveryType, o.DeliveryAddress, o.Notes,
                o.CreatedAt, o.UpdatedAt,
                Supplier = new { o.Supplier.CompanyName, o.Supplier.Phone },
                Items = o.Items.Select(i => new
                {
                    i.ProductId, i.Product.Name, i.Quantity, i.UnitPrice, i.LineTotal
                })
            })
            .ToListAsync();

        return Ok(ApiResponse<object>.Ok(new { total, page, pageSize, items }));
    }

    /// <summary>
    /// Get a single order by ID.
    /// </summary>
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id)
    {
        var shop = await db.SpazaShops.FirstOrDefaultAsync(s => s.UserId == UserId);
        if (shop is null) return NotFound(ApiResponse.Fail("Shop not found."));

        var order = await db.Orders
            .Include(o => o.Supplier)
            .Include(o => o.Items).ThenInclude(i => i.Product)
            .FirstOrDefaultAsync(o => o.Id == id && o.ShopId == shop.Id);

        if (order is null) return NotFound(ApiResponse.Fail("Order not found."));

        return Ok(ApiResponse<object>.Ok(new
        {
            order.Id, order.OrderNumber, order.Status, order.TotalAmount,
            order.Subtotal, order.DeliveryFee, order.PlatformCommission,
            order.DeliveryType, order.DeliveryAddress, order.Notes,
            order.CreatedAt, order.UpdatedAt,
            Supplier = new { order.Supplier.CompanyName, order.Supplier.Phone, order.Supplier.Email },
            Items = order.Items.Select(i => new
            {
                i.ProductId, i.Product.Name, i.Quantity, i.UnitPrice, i.LineTotal
            })
        }));
    }

    /// <summary>
    /// Place a new order from the shop's cart.
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> PlaceOrder([FromBody] PlaceOrderRequest req)
    {
        var shop = await db.SpazaShops.FirstOrDefaultAsync(s => s.UserId == UserId);
        if (shop is null) return NotFound(ApiResponse.Fail("Shop not found."));

        if (req.Items == null || req.Items.Count == 0)
            return BadRequest(ApiResponse.Fail("Order must have at least one item."));

        // Look up products and calculate totals
        var productIds = req.Items.Select(i => i.ProductId).ToList();
        var products = await db.Products
            .Where(p => productIds.Contains(p.Id))
            .ToDictionaryAsync(p => p.Id);

        if (products.Count != productIds.Count)
            return BadRequest(ApiResponse.Fail("One or more products not found."));

        // All items must be from the same supplier
        var supplierIds = products.Values.Select(p => p.SupplierId).Distinct().ToList();
        if (supplierIds.Count > 1)
            return BadRequest(ApiResponse.Fail("All items must be from the same supplier."));

        var supplierId = supplierIds.First();
        var supplier = await db.Suppliers.FindAsync(supplierId);
        if (supplier is null) return BadRequest(ApiResponse.Fail("Supplier not found."));

        var orderItems = new List<OrderItem>();
        decimal subtotal = 0;
        foreach (var item in req.Items)
        {
            var product = products[item.ProductId];
            var lineTotal = product.Price * item.Quantity;
            subtotal += lineTotal;
            orderItems.Add(new OrderItem
            {
                ProductId = item.ProductId,
                Quantity = item.Quantity,
                UnitPrice = product.Price,
                LineTotal = lineTotal
            });
        }

        var deliveryFee = req.DeliveryType == "express" ? 150m : 100m;
        var commission = subtotal * (supplier.CommissionRate / 100m);
        var total = subtotal + deliveryFee + commission;

        var orderNumber = $"SPZ-{DateTime.UtcNow:yyyy}-{Random.Shared.Next(1000, 9999):0000}";
        var order = new Order
        {
            OrderNumber = orderNumber,
            ShopId = shop.Id,
            SupplierId = supplierId,
            Status = "pending",
            DeliveryType = req.DeliveryType ?? "standard",
            DeliveryAddress = req.DeliveryAddress ?? shop.Address,
            Subtotal = subtotal,
            DeliveryFee = deliveryFee,
            PlatformCommission = commission,
            TotalAmount = total,
            Notes = req.Notes,
            Items = orderItems
        };

        db.Orders.Add(order);
        await db.SaveChangesAsync();

        return Ok(ApiResponse<object>.Ok(new
        {
            order.Id, order.OrderNumber, order.Status, order.TotalAmount,
            order.Subtotal, order.DeliveryFee, order.PlatformCommission,
            order.DeliveryType
        }));
    }

    /// <summary>
    /// Confirm delivery of an order.
    /// </summary>
    [HttpPatch("{id:guid}/confirm-delivery")]
    public async Task<IActionResult> ConfirmDelivery(Guid id)
    {
        var shop = await db.SpazaShops.FirstOrDefaultAsync(s => s.UserId == UserId);
        if (shop is null) return NotFound(ApiResponse.Fail("Shop not found."));

        var order = await db.Orders.FirstOrDefaultAsync(o => o.Id == id && o.ShopId == shop.Id);
        if (order is null) return NotFound(ApiResponse.Fail("Order not found."));

        if (order.Status != "dispatched")
            return BadRequest(ApiResponse.Fail($"Cannot confirm delivery for order in '{order.Status}' status."));

        order.Status = "delivered";
        await db.SaveChangesAsync();

        return Ok(ApiResponse<object>.Ok(new { order.Id, order.Status, deliveredAt = order.UpdatedAt }));
    }
}

public record PlaceOrderRequest(
    List<OrderItemRequest> Items,
    string? DeliveryType,
    string? DeliveryAddress,
    string? PaymentMethod,
    string? Notes
);

public record OrderItemRequest(Guid ProductId, int Quantity);
