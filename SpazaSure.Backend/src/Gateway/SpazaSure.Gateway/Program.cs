using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddCors(opt => opt.AddPolicy("Portal", p =>
    p.AllowAnyOrigin()
     .AllowAnyHeader()
     .AllowAnyMethod()));

builder.Services.AddReverseProxy()
    .LoadFromConfig(builder.Configuration.GetSection("ReverseProxy"));

// Unified Swagger aggregator
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "SpazaSure API Gateway",
        Version = "v1",
        Description = "Unified API dashboard for all SpazaSure microservices"
    });
});

var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

app.UseCors("Portal");

// Single Swagger UI at /swagger  shows all services in one dropdown
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.DocumentTitle = "SpazaSure API Dashboard";
    c.SwaggerEndpoint("http://localhost:5001/swagger/v1/swagger.json", "Auth Service (5001)");
    c.SwaggerEndpoint("http://localhost:5002/swagger/v1/swagger.json", "Product Service (5002)");
    c.SwaggerEndpoint("http://localhost:5003/swagger/v1/swagger.json", "Order Service (5003)");
    c.SwaggerEndpoint("http://localhost:5004/swagger/v1/swagger.json", "Analytics Service (5004)");
    c.SwaggerEndpoint("http://localhost:5005/swagger/v1/swagger.json", "User Service (5005)");
    c.SwaggerEndpoint("http://localhost:5006/swagger/v1/swagger.json", "Compliance Service (5006)");
    c.RoutePrefix = "swagger";
    c.DefaultModelsExpandDepth(-1); // collapse schemas by default for cleaner view
    c.DisplayRequestDuration();
});

app.MapReverseProxy();

app.Run();

