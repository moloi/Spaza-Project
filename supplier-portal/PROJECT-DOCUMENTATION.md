# SpazaSure Supplier Portal — Project Documentation

## Server Information

| Property | Value |
|----------|-------|
| **Server Name** | spazasure-qaCPX32 |
| **Architecture** | x86 |
| **Storage** | 160 GB + 110 GB |
| **Region** | eu-central (Falkenstein) |
| **IP Address** | 167.233.69.205 |
| **Provider** | Hetzner Cloud |
| **Web Server** | Nginx (serves static SPA) |
| **Deploy Path** | `/var/www/spazasure` |

---

## 1. Project Overview

**SpazaSure Supplier Portal** is a React single-page application (SPA) that provides:
- A **Supplier Portal** for managing products, orders, analytics, profiles, and subscriptions
- An **Admin Portal** for managing suppliers, verifying documents, moderating products, and platform analytics

The frontend is a static build served by Nginx. The backend API runs separately.

---

## 2. Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| UI Framework | React | 18.3 |
| Language | TypeScript | 5.7 |
| Build Tool | Vite | 6.4 |
| Routing | React Router DOM | 6.28 |
| State Management | Zustand | 5.0 |
| HTTP Client | Axios | 1.7 |
| Forms | React Hook Form + Zod | 7.54 / 3.24 |
| Styling | Tailwind CSS | 3.4 |
| Icons | Lucide React | 0.468 |
| Charts | Recharts | 2.14 |
| Notifications | React Hot Toast | 2.4 |
| Date Utilities | date-fns | 4.1 |
| Barcode | React Barcode | 1.6 |

---

## 3. Project Structure

```
supplier-portal/
├── .env                          # Default env (fallback)
├── .env.development              # Dev: localhost:5181
├── .env.qa                       # QA: 167.233.69.205
├── .env.production               # Prod: api.spazasure.co.za
├── .env.example                  # Template for new environments
│
├── .github/workflows/
│   ├── deploy-qa.yml             # develop branch → QA server
│   └── deploy-prod.yml           # main branch → Production server
│
├── index.html                    # Vite SPA entry point
├── package.json                  # Dependencies & build scripts
├── postcss.config.js             # Tailwind + Autoprefixer
├── public/
│   └── spazasure_logo.jpg        # App logo
│
└── src/
    ├── main.tsx                  # React entry (BrowserRouter, Toaster)
    ├── App.tsx                   # All routing + RequireAuth guard
    ├── index.css                 # Global Tailwind imports
    ├── vite-env.d.ts             # Vite type declarations
    │
    ├── config/
    │   └── env.ts                # Typed env variable access
    │
    ├── types/
    │   └── index.ts              # All TypeScript interfaces
    │
    ├── store/
    │   └── authStore.ts          # Zustand: auth state (JWT, user, role)
    │
    ├── services/
    │   ├── api.ts                # Axios client + all API modules
    │   └── mockData.ts           # Seed data for development
    │
    ├── hooks/
    │   └── useAsync.ts           # Generic async data-fetching hook
    │
    ├── components/
    │   ├── layout/
    │   │   ├── AppLayout.tsx     # Supplier shell (sidebar + header + outlet)
    │   │   ├── AdminLayout.tsx   # Admin shell (sidebar + header + outlet)
    │   │   ├── Sidebar.tsx       # Supplier nav sidebar
    │   │   └── AdminSidebar.tsx  # Admin nav sidebar
    │   └── ui/
    │       ├── index.tsx         # Barrel exports (Avatar, etc.)
    │       ├── GlobalSearch.tsx   # Search overlay
    │       ├── LiveClock.tsx      # Real-time clock
    │       ├── NotificationBell.tsx
    │       ├── PageLoader.tsx     # Loading spinner
    │       └── PageTransition.tsx # Animated transitions
    │
    ├── pages/
    │   ├── auth/
    │   │   ├── LoginPage.tsx
    │   │   ├── RegisterPage.tsx
    │   │   └── ForgotPasswordPage.tsx
    │   ├── dashboard/
    │   │   └── DashboardPage.tsx
    │   ├── products/
    │   │   ├── ProductsPage.tsx
    │   │   ├── ProductFormModal.tsx
    │   │   └── BarcodeModal.tsx
    │   ├── orders/
    │   │   ├── OrdersPage.tsx
    │   │   └── OrderDetailModal.tsx
    │   ├── analytics/
    │   │   └── AnalyticsPage.tsx
    │   ├── notifications/
    │   │   └── NotificationsPage.tsx
    │   ├── profile/
    │   │   └── ProfilePage.tsx
    │   ├── subscription/
    │   │   └── SubscriptionPage.tsx
    │   └── admin/
    │       ├── AdminDashboardPage.tsx
    │       ├── AdminSuppliersPage.tsx
    │       ├── DocumentVerificationPage.tsx
    │       ├── AdminProductsPage.tsx
    │       ├── AdminOrdersPage.tsx
    │       ├── AdminAnalyticsPage.tsx
    │       ├── AdminNotificationsPage.tsx
    │       ├── AdminSettingsPage.tsx
    │       └── AdminComingSoon.tsx
    │
    └── utils/
        └── index.ts              # Utility helpers (formatCurrency, etc.)
```

---

## 4. Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        BROWSER                               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────┐    ┌──────────────┐    ┌──────────────────┐  │
│  │  Zustand  │    │  React Router │    │  Axios + JWT     │  │
│  │  Auth     │◄──►│  (App.tsx)    │───►│  Interceptors    │  │
│  │  Store    │    │               │    │                  │  │
│  └──────────┘    └──────┬───────┘    └────────┬─────────┘  │
│                          │                      │            │
│         ┌────────────────┼──────────────────────┘           │
│         │                │                                   │
│  ┌──────▼──────┐  ┌─────▼──────┐                           │
│  │  Supplier   │  │   Admin     │                           │
│  │  Portal     │  │   Portal    │                           │
│  │  (AppLayout)│  │  (AdminLay) │                           │
│  └─────────────┘  └────────────┘                           │
│                                                              │
└──────────────────────────────┬──────────────────────────────┘
                               │ HTTPS/HTTP
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    NGINX (167.233.69.205)                     │
│         Serves /var/www/spazasure (static dist)              │
│         Proxies /api → Backend API                           │
└──────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    BACKEND API                                │
│         QA:   http://167.233.69.205/api                      │
│         Prod: https://api.spazasure.co.za/api                │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. Routing & Access Control

### Public Routes (no auth required)
| Path | Page |
|------|------|
| `/login` | LoginPage |
| `/register` | RegisterPage |
| `/forgot-password` | ForgotPasswordPage |

### Supplier Routes (role: `supplier`)
| Path | Page | Description |
|------|------|-------------|
| `/dashboard` | DashboardPage | Overview, stats, recent orders |
| `/products` | ProductsPage | CRUD product catalog |
| `/orders` | OrdersPage | View & manage orders |
| `/analytics` | AnalyticsPage | Revenue charts, top products |
| `/notifications` | NotificationsPage | System notifications |
| `/profile` | ProfilePage | Company info, documents, bank |
| `/subscription` | SubscriptionPage | Tier management, PayFast |

### Admin Routes (role: `admin`)
| Path | Page | Description |
|------|------|-------------|
| `/admin/dashboard` | AdminDashboardPage | Platform overview |
| `/admin/suppliers` | AdminSuppliersPage | Manage/verify suppliers |
| `/admin/documents` | DocumentVerificationPage | Document review |
| `/admin/products` | AdminProductsPage | Approve/reject products |
| `/admin/orders` | AdminOrdersPage | All platform orders |
| `/admin/analytics` | AdminAnalyticsPage | Platform analytics |
| `/admin/notifications` | AdminNotificationsPage | Admin notifications |
| `/admin/settings` | AdminSettingsPage | Platform settings |

---

## 6. API Endpoints (Frontend Consumes)

### Authentication (`/supplier/auth/`)
- `POST /login` — Login (email, password, role)
- `POST /register` — Register new supplier
- `POST /refresh` — Refresh JWT token
- `POST /logout` — Invalidate refresh token
- `POST /forgot-password` — Send reset email
- `POST /reset-password` — Reset with token

### Products (`/supplier/products/`)
- `GET /` — List (paginated, search, filter)
- `GET /:id` — Get single product
- `POST /` — Create product
- `PUT /:id` — Update product
- `DELETE /:id` — Delete product
- `PATCH /:id/toggle` — Toggle availability
- `GET /:id/barcode` — Get barcode

### Orders (`/supplier/orders/`)
- `GET /` — List (paginated, status filter)
- `GET /:id` — Get order details
- `PATCH /:id/status` — Update order status

### Analytics (`/supplier/analytics/`)
- `GET /summary` — Dashboard stats
- `GET /revenue` — Revenue over time (week/month/year)
- `GET /top-products` — Best-selling products

### Profile (`/supplier/profile/`)
- `GET /` — Get supplier profile
- `PUT /` — Update profile
- `POST /documents` — Upload compliance document
- `POST /logo` — Upload company logo

### Subscription (`/supplier/subscription/`)
- `GET /plans` — Available plans
- `GET /current` — Current subscription
- `POST /subscribe` — Subscribe to plan
- `POST /:id/confirm-payment` — Confirm payment
- `POST /cancel` — Cancel subscription
- `GET /history` — Billing history

### Payment (`/supplier/payment/`)
- `POST /initiate` — Start PayFast payment
- `GET /status/:id` — Check payment status

### Admin Suppliers (`/admin/suppliers/`)
- `GET /` — List suppliers
- `GET /:id` — Supplier details
- `PATCH /:id/verify` — Verify supplier
- `PATCH /:id/suspend` — Suspend supplier

### Admin Products (`/admin/products/`)
- `GET /` — List all products
- `PATCH /:id/approve` — Approve product
- `PATCH /:id/reject` — Reject product
- `PATCH /:id/toggle` — Toggle availability

### Admin Spaza Owners (`/admin/spaza-owners/`)
- `GET /` — List spaza shop owners
- `GET /:id` — Owner details
- `PATCH /:id/verify` — Verify owner
- `PATCH /:id/suspend` — Suspend owner

### Admin FAQs (`/admin/faqs/`)
- `GET /` — List all FAQs
- `POST /` — Create FAQ
- `PUT /:id` — Update FAQ
- `DELETE /:id` — Delete FAQ
- `PATCH /reorder` — Reorder FAQs

---

## 7. Environment Configuration

| Variable | Development | QA | Production |
|----------|-------------|-----|------------|
| `VITE_API_URL` | `http://localhost:5181/api` | `http://167.233.69.205/api` | `https://api.spazasure.co.za/api` |
| `VITE_APP_NAME` | SpazaSure Supplier Portal | SpazaSure Supplier Portal (QA) | SpazaSure Supplier Portal |
| `VITE_APP_ENV` | development | qa | production |
| `VITE_ENABLE_DEBUG` | true | true | false |
| `VITE_ENABLE_MOCK_DATA` | false | false | false |
| `VITE_API_TIMEOUT` | 10000 | 15000 | 30000 |

---

## 8. Build & Deploy

### NPM Scripts
```bash
npm run dev              # Local dev server (Vite, mode=development)
npm run build            # Production build (tsc + vite, mode=production)
npm run build:qa         # QA build (tsc + vite, mode=qa)
npm run build:prod       # Same as build (explicit)
npm run preview          # Preview production build locally
```

### CI/CD Pipeline (GitHub Actions)

**QA Deployment:**
- Trigger: Push to `develop` branch
- Steps: checkout → Node 20 → npm ci → build:qa → SCP to QA server → restart Nginx

**Production Deployment:**
- Trigger: Push to `main` branch
- Steps: checkout → Node 20 → npm ci → build:prod → SCP to prod server → restart Nginx

### GitHub Secrets Required
| Secret | Purpose |
|--------|---------|
| `QA_HOST` | QA server IP (167.233.69.205) |
| `QA_SSH_KEY` | SSH private key for QA server |
| `PROD_HOST` | Production server IP |
| `PROD_SSH_KEY` | SSH private key for production |

---

## 9. Authentication Flow

```
1. User logs in → POST /supplier/auth/login
2. Backend returns: { token, refreshToken, tokenExpiresAt, user info }
3. Stored in Zustand → persisted to localStorage (key: spazasure-auth-v2)
4. Axios interceptor attaches Bearer token to every request
5. On 401 response:
   a. Extract refreshToken from localStorage
   b. POST /supplier/auth/refresh → get new tokens
   c. Update localStorage
   d. Retry original request with new token
   e. If refresh fails → clear storage → redirect to /login
```

---

## 10. Data Types Summary

| Type | Description |
|------|-------------|
| `AuthUser` | Logged-in user (id, email, role, tier, tokens) |
| `Product` | Catalog item (name, SKU, price, stock, status, images) |
| `Order` | Purchase order (items, totals, status, delivery, payment) |
| `SupplierProfile` | Company details, bank info, compliance docs |
| `ComplianceDoc` | Uploaded document (CIPC, tax clearance, BEE, license) |
| `SubscriptionPlan` | Tier plan (pricing, features, limits) |
| `SubscriptionRecord` | Active subscription record |
| `AnalyticsSummary` | Revenue, orders, products stats |

### User Roles
- `supplier` — Can manage own products, orders, profile, subscription
- `admin` — Can manage all suppliers, approve products/docs, view platform analytics

### Subscription Tiers
- `basic` → `bronze` → `silver` → `gold`
- Higher tiers unlock: more listings, lower commission, analytics, API access, priority support

---

## 11. Project Health Assessment

### ✅ Clean & Well-Structured
- Clear separation: pages / components / services / store / types
- Typed API layer with proper mapping between backend and frontend shapes
- Environment-based configuration with typed access
- Role-based routing with auth guards
- CI/CD automation for both QA and production

### ✅ Good Practices
- Token refresh with automatic retry (silent re-auth)
- Centralized error handling with user-facing toasts
- LocalStorage persistence for auth state
- Separate env files per environment
- TypeScript throughout

### ⚠️ Areas to Monitor
- `react-query` v3 is deprecated (consider upgrading to `@tanstack/react-query` v5)
- No test files found (no unit/integration tests)
- No ESLint/Prettier configuration visible
- `node_modules` and `dist` should be in `.gitignore` (verify)
- Mock data file exists but `VITE_ENABLE_MOCK_DATA` is false everywhere

---

## 12. QA Server Quick Reference

```
Server:     spazasure-qaCPX32
IP:         167.233.69.205
Location:   Hetzner, Falkenstein (eu-central)
OS:         Linux (Ubuntu presumed)
Web:        Nginx
Deploy Dir: /var/www/spazasure
API URL:    http://167.233.69.205/api
Branch:     develop → auto-deploys here
```

---

*Generated: June 10, 2026*
