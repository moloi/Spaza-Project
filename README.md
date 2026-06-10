# SpazaSure Platform

B2B2C digital ecosystem connecting **Suppliers**, **Spaza Shops**, and **Consumers** in South Africa.

---

## Project Structure

```
Spaza Project/
├── docs/                          # Architecture & business documents
├── spazasure_app/                 # Spaza Shop Mobile App (Flutter) ✅ EXISTING
├── supplier-portal/               # Supplier Web Portal (React.js + TypeScript) ✅ NEW
└── consumer_app/                  # Consumer Verification App (Flutter) ✅ NEW
```

---

## 1. Supplier Web Portal (`supplier-portal/`)

**Stack:** React 18 + TypeScript + Vite + Tailwind CSS + Zustand + Recharts

### Features
- Login / Register with form validation (Zod + React Hook Form)
- Dashboard with KPI cards and revenue/orders charts
- Product catalog management (add, edit, toggle availability, delete)
- Order management with status workflow (pending → processing → dispatched → delivered)
- Analytics with revenue trends, order distribution, top products
- Supplier profile & compliance document management

### Setup
```bash
cd supplier-portal
cp .env.example .env
npm install
npm run dev        # http://localhost:3000
npm run build      # Production build
```

### API Integration
Replace mock data in `src/services/api.ts` with your C# microservice endpoints.
The API base URL is configured via `VITE_API_URL` in `.env`.

---

## 2. Consumer Verification App (`consumer_app/`)

**Stack:** Flutter + Provider + mobile_scanner + shared_preferences

### Features
- Onboarding flow (3 screens)
- QR code scanner with custom overlay
- Instant verification result (Authentic ✅ / Warning ⚠️ / Counterfeit ❌ / Not Found)
- Product details: brand, supplier, certifications, batch/expiry info
- Safety tips for counterfeit/warning results
- Report counterfeit form
- Scan history (persisted locally)
- Manual code entry fallback

### Setup
```bash
cd consumer_app
flutter pub get
flutter run
```

### API Integration
Set `API_URL` via `--dart-define`:
```bash
flutter run --dart-define=API_URL=http://your-api.com/api
```

---

## 3. Spaza Shop App (`spazasure_app/`)

**Stack:** Flutter (existing)

Already built with marketplace, ordering, cart, delivery tracking, compliance, and notifications.

---

## 4. C# Microservices Backend

### Required Endpoints for Supplier Portal
| Method | Endpoint | Service |
|--------|----------|---------|
| POST | `/api/supplier/auth/login` | Auth Service |
| POST | `/api/supplier/auth/register` | Auth Service |
| GET/POST/PUT/DELETE | `/api/supplier/products` | Product Service |
| GET/PATCH | `/api/supplier/orders` | Order Service |
| GET | `/api/supplier/analytics/summary` | Analytics Service |
| GET | `/api/supplier/analytics/revenue` | Analytics Service |
| GET/PUT | `/api/supplier/profile` | User Service |
| POST | `/api/supplier/profile/documents` | Compliance Service |

### Required Endpoints for Consumer App
| Method | Endpoint | Service |
|--------|----------|---------|
| GET | `/api/verify/{qrCode}` | Verification Service |
| POST | `/api/verify/report` | Compliance Service |

---

## Architecture Alignment

| Component | Technology | Status |
|-----------|-----------|--------|
| Supplier Web Portal | React.js + TypeScript | ✅ Built |
| Spaza Shop App | Flutter | ✅ Existing |
| Consumer App | Flutter | ✅ Built |
| Admin Dashboard | React.js + TypeScript | 🔜 Phase 2 |
| API Gateway | AWS API Gateway / Kong | 🔜 Backend |
| Auth Service | C# .NET | 🔜 Backend |
| Product Service | C# .NET | 🔜 Backend |
| Order Service | C# .NET | 🔜 Backend |
| Payment Service | C# .NET | 🔜 Backend |
| Verification Service | C# .NET | 🔜 Backend |
| Analytics Service | C# .NET | 🔜 Backend |

---

## Phase Roadmap

- **Phase 1 (MVP):** Supplier portal + Spaza shop app + basic admin + EFT payments ✅
- **Phase 2:** Consumer app + group buying + wallet + premium subscriptions ✅
- **Phase 3:** Advanced analytics + financial services + advertising platform
