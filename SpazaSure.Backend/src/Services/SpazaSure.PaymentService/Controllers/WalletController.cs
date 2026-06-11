using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SpazaSure.Infrastructure.Data;
using SpazaSure.Shared.Models;
using System.Security.Claims;

namespace SpazaSure.PaymentService.Controllers;

[ApiController]
[Route("api/shop/wallet")]
[Authorize]
public class WalletController(SpazaSureDbContext db) : ControllerBase
{
    private Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    /// <summary>
    /// Get wallet balance for the current shop.
    /// </summary>
    [HttpGet("balance")]
    public async Task<IActionResult> GetBalance()
    {
        var shop = await db.SpazaShops.FirstOrDefaultAsync(s => s.UserId == UserId);
        if (shop is null) return NotFound(ApiResponse.Fail("Shop not found."));

        // For now, calculate balance from delivered orders (simplified wallet)
        // In production this would use a dedicated wallet_transactions table
        var totalSpent = await db.Orders
            .Where(o => o.ShopId == shop.Id && o.Status == "delivered")
            .SumAsync(o => (decimal?)o.TotalAmount) ?? 0;

        return Ok(ApiResponse<object>.Ok(new
        {
            shopId = shop.Id,
            balance = 0m, // Wallet starts at 0, topped up via payments
            totalSpent,
            currency = "ZAR"
        }));
    }

    /// <summary>
    /// Request a wallet top-up. Returns payment details for EFT or redirect URL.
    /// </summary>
    [HttpPost("topup")]
    public async Task<IActionResult> TopUp([FromBody] TopUpRequest req)
    {
        if (req.Amount <= 0)
            return BadRequest(ApiResponse.Fail("Amount must be greater than zero."));

        var shop = await db.SpazaShops.FirstOrDefaultAsync(s => s.UserId == UserId);
        if (shop is null) return NotFound(ApiResponse.Fail("Shop not found."));

        // Generate payment reference
        var reference = $"WAL-{shop.Id.ToString()[..8].ToUpper()}-{DateTime.UtcNow:yyyyMMddHHmmss}";

        // In production: integrate with PayFast/Yoco to generate a payment URL
        // For now, return EFT banking details or a mock payment URL
        var paymentInfo = req.Method?.ToLower() switch
        {
            "payfast" => new
            {
                method = "payfast",
                redirectUrl = $"https://sandbox.payfast.co.za/eng/process?merchant_id=10000100&amount={req.Amount}&item_name=Wallet+TopUp&payment_id={reference}",
                reference,
                status = "pending"
            } as object,
            _ => new
            {
                method = "eft",
                bankName = "FNB",
                accountNumber = "62000000000",
                branchCode = "250655",
                accountType = "Business Cheque",
                reference,
                amount = req.Amount,
                status = "pending"
            } as object
        };

        return Ok(ApiResponse<object>.Ok(new
        {
            topUpId = Guid.NewGuid(),
            amount = req.Amount,
            currency = "ZAR",
            payment = paymentInfo
        }));
    }

    /// <summary>
    /// Get transaction history for the current shop.
    /// </summary>
    [HttpGet("transactions")]
    public async Task<IActionResult> GetTransactions([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var shop = await db.SpazaShops.FirstOrDefaultAsync(s => s.UserId == UserId);
        if (shop is null) return NotFound(ApiResponse.Fail("Shop not found."));

        // Build transaction history from orders
        var query = db.Orders
            .Include(o => o.Supplier)
            .Where(o => o.ShopId == shop.Id && (o.Status == "delivered" || o.Status == "processing" || o.Status == "dispatched"))
            .OrderByDescending(o => o.CreatedAt);

        var total = await query.CountAsync();
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(o => new
            {
                id = o.Id,
                type = "order_payment",
                description = $"Order #{o.OrderNumber} - {o.Supplier.CompanyName}",
                amount = -o.TotalAmount, // Negative = money out
                status = o.Status == "delivered" ? "completed" : "pending",
                date = o.CreatedAt,
                reference = o.OrderNumber
            })
            .ToListAsync();

        return Ok(ApiResponse<object>.Ok(new { total, page, pageSize, transactions = items }));
    }
}

public record TopUpRequest(decimal Amount, string? Method);
