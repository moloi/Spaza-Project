import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Package, ShoppingCart, DollarSign, TrendingUp, AlertTriangle,
  CheckCircle, ArrowRight, Clock, Plus, BarChart2, Bell,
  Zap, ArrowUpRight, Activity,
} from 'lucide-react';
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, BarChart, Bar,
} from 'recharts';
import { StatCard, OrderStatusBadge, AlertBanner, SectionHeader } from '../../components/ui';
import PageLoader from '../../components/ui/PageLoader';
import { analyticsApi, ordersApi, profileApi } from '../../services/api';
import { useAuthStore } from '../../store/authStore';
import { format } from 'date-fns';
import type { AnalyticsSummary, RevenueDataPoint, TopProduct, Order, ComplianceDoc } from '../../types';

const quickActions = [
  { label: 'Add Product',   icon: Plus,        to: '/products',      color: 'bg-primary-50 text-primary hover:bg-primary-100 border-primary-100' },
  { label: 'View Orders',   icon: ShoppingCart, to: '/orders',        color: 'bg-blue-50 text-blue-600 hover:bg-blue-100 border-blue-100' },
  { label: 'Analytics',     icon: BarChart2,    to: '/analytics',     color: 'bg-violet-50 text-violet-600 hover:bg-violet-100 border-violet-100' },
  { label: 'Notifications', icon: Bell,         to: '/notifications', color: 'bg-amber-50 text-amber-600 hover:bg-amber-100 border-amber-100' },
];

const PIPELINE_META = [
  { status: 'pending',    label: 'Awaiting Acceptance', color: 'bg-amber-400' },
  { status: 'processing', label: 'Being Prepared',      color: 'bg-violet-400' },
  { status: 'dispatched', label: 'Out for Delivery',    color: 'bg-indigo-400' },
  { status: 'delivered',  label: 'Completed',           color: 'bg-emerald-400' },
];

const DOC_META: { docType: string; label: string }[] = [
  { docType: 'cipc_certificate', label: 'CIPC Certificate' },
  { docType: 'tax_clearance',    label: 'Tax Clearance' },
  { docType: 'bee_certificate',  label: 'BEE Certificate' },
  { docType: 'product_license',  label: 'Product License' },
];

export default function DashboardPage() {
  const { user } = useAuthStore();
  const navigate = useNavigate();
  const [alertDismissed, setAlertDismissed] = useState(false);
  const [loading, setLoading] = useState(true);

  const [summary, setSummary] = useState<AnalyticsSummary | null>(null);
  const [revenue, setRevenue] = useState<RevenueDataPoint[]>([]);
  const [topProducts, setTopProducts] = useState<TopProduct[]>([]);
  const [recentOrders, setRecentOrders] = useState<Order[]>([]);
  const [pipelineCounts, setPipelineCounts] = useState<Record<string, number>>({ pending: 0, processing: 0, dispatched: 0, delivered: 0 });
  const [docs, setDocs] = useState<ComplianceDoc[]>([]);

  useEffect(() => {
    let cancelled = false;
    const load = async () => {
      try {
        const [summaryRes, revenueRes, topRes, ordersRes, profileRes] = await Promise.allSettled([
          analyticsApi.summary(),
          analyticsApi.revenue('month'),
          analyticsApi.topProducts(),
          ordersApi.list({ pageSize: 50 }),
          profileApi.get(),
        ]);

        if (cancelled) return;

        if (summaryRes.status === 'fulfilled') {
          const d = (summaryRes.value as any)?.data ?? summaryRes.value;
          setSummary({
            totalRevenue:   d.totalRevenue   ?? 0,
            totalOrders:    d.totalOrders    ?? 0,
            activeProducts: d.activeProducts ?? 0,
            avgOrderValue:  d.totalOrders > 0 ? Math.round(d.totalRevenue / d.totalOrders) : 0,
            revenueChange:  d.revenueGrowth  ?? d.revenueChange  ?? 0,
            ordersChange:   d.ordersGrowth   ?? d.ordersChange   ?? 0,
          });
        }

        if (revenueRes.status === 'fulfilled') {
          const raw: any[] = (revenueRes.value as any)?.data ?? revenueRes.value ?? [];
          setRevenue(raw.map((r) => ({
            month:   r.month ?? r.date ?? '',
            revenue: r.revenue ?? 0,
            orders:  r.orders  ?? 0,
          })));
        }

        if (topRes.status === 'fulfilled') {
          const raw: any[] = (topRes.value as any)?.data ?? topRes.value ?? [];
          setTopProducts(raw.map((r) => ({
            productId:   r.productId ?? r.id ?? '',
            productName: r.name ?? r.productName ?? '',
            totalSold:   r.unitsSold ?? r.totalSold ?? 0,
            revenue:     r.revenue ?? 0,
          })));
        }

        if (ordersRes.status === 'fulfilled') {
          const raw: any[] = (ordersRes.value as any)?.data?.items ?? (ordersRes.value as any)?.data ?? (ordersRes.value as any)?.items ?? [];
          const mapped: Order[] = raw.map((o: any) => ({
            id:             o.id,
            orderNumber:    o.orderNumber,
            shopId:         o.shop?.id ?? '',
            shopName:       o.shop?.shopName ?? o.shopName ?? '',
            shopAddress:    o.shop?.address ?? o.deliveryAddress ?? '',
            items:          (o.items ?? []).map((i: any) => ({
              productId:    i.productId,
              productName:  i.name ?? i.productName ?? '',
              productImage: '',
              quantity:     i.quantity,
              price:        i.unitPrice ?? i.price ?? 0,
            })),
            subtotal:       o.totalAmount ?? 0,
            deliveryFee:    0,
            platformFee:    0,
            total:          o.totalAmount ?? 0,
            status:         o.status,
            deliveryOption: o.deliveryType ?? 'standard',
            paymentMethod:  'eft',
            paymentStatus:  'held',
            createdAt:      o.createdAt,
          }));
          setRecentOrders(mapped.slice(0, 5));
          const counts = { pending: 0, processing: 0, dispatched: 0, delivered: 0 };
          mapped.forEach((o) => { if (o.status in counts) (counts as any)[o.status]++; });
          setPipelineCounts(counts);
        }

        if (profileRes.status === 'fulfilled') {
          const d = (profileRes.value as any)?.data ?? profileRes.value;
          const rawDocs: any[] = d?.documents ?? [];
          setDocs(rawDocs.map((d: any) => ({
            id:       d.id,
            docType:  d.docType,
            docUrl:   d.docUrl ?? '',
            status:   d.status,
            expiryDate: d.expiryDate,
          })));
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    };
    load();
    return () => { cancelled = true; };
  }, []);

  if (loading) return <PageLoader variant="dashboard" />;

  const s = summary;
  const pendingCount = pipelineCounts.pending;
  const pipelineTotal = Object.values(pipelineCounts).reduce((a, b) => a + b, 0);
  const orderTimeline = PIPELINE_META.map((m) => ({ ...m, count: pipelineCounts[m.status] ?? 0 }));
  const beePending = docs.some((d) => d.docType === 'bee_certificate' && d.status === 'pending');

  const hour = new Date().getHours();
  const greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

  return (
    <div className="p-6 space-y-5 animate-in">
      {/* Welcome Banner */}
      <div className="bg-gradient-primary rounded-2xl p-6 text-white relative overflow-hidden shadow-card-lg">
        {/* Decorative blobs */}
        <div className="absolute top-0 right-0 w-56 h-56 bg-white/5 rounded-full -translate-y-1/2 translate-x-1/4 pointer-events-none" />
        <div className="absolute bottom-0 right-32 w-40 h-40 bg-white/5 rounded-full translate-y-1/2 pointer-events-none" />
        <div className="absolute top-1/2 right-16 w-20 h-20 bg-accent/10 rounded-full -translate-y-1/2 pointer-events-none" />

        <div className="relative z-10 flex items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <span className="text-xs font-bold text-green-300 uppercase tracking-widest">
                {format(new Date(), 'EEEE, d MMMM yyyy')}
              </span>
              <span className="w-1 h-1 rounded-full bg-green-400" />
              <span className="flex items-center gap-1 text-xs font-semibold text-emerald-300">
                <Activity size={11} className="animate-pulse-soft" /> Live
              </span>
            </div>
            <h1 className="text-2xl font-black text-white leading-tight">
              {greeting}, {user?.companyName?.split(' ')[0]} 👋
            </h1>
            <p className="text-green-200/80 text-sm mt-1">Here's your business snapshot for today.</p>

            {/* Mini performance bar */}
            <div className="flex items-center gap-3 mt-4">
              <div className="flex items-center gap-1.5 bg-white/10 border border-white/15 rounded-full px-3 py-1.5">
                <TrendingUp size={12} className="text-green-300" />
                <span className="text-xs font-bold text-white">{s && s.revenueChange >= 0 ? '+' : ''}{s?.revenueChange ?? 0}% revenue</span>
              </div>
              <div className="flex items-center gap-1.5 bg-white/10 border border-white/15 rounded-full px-3 py-1.5">
                <ShoppingCart size={12} className="text-green-300" />
                <span className="text-xs font-bold text-white">{pendingCount} order{pendingCount !== 1 ? 's' : ''} need action</span>
              </div>
            </div>
          </div>

          <div className="hidden md:flex items-center gap-2.5 flex-shrink-0">
            <button
              onClick={() => navigate('/products')}
              className="flex items-center gap-2 bg-white/15 hover:bg-white/25 text-white text-sm font-semibold px-4 py-2.5 rounded-xl transition-all border border-white/20 backdrop-blur-sm"
            >
              <Plus size={15} /> Add Product
            </button>
            <button
              onClick={() => navigate('/orders')}
              className="flex items-center gap-2 bg-white text-primary text-sm font-bold px-4 py-2.5 rounded-xl hover:bg-green-50 transition-all shadow-md"
            >
              View Orders <ArrowRight size={15} />
            </button>
          </div>
        </div>
      </div>

      {/* Compliance Alert */}
      {!alertDismissed && beePending && (
        <AlertBanner
          type="warning"
          message="⚠️ Your BEE Certificate is pending review. Upload it to maintain full compliance and avoid account restrictions."
          onDismiss={() => setAlertDismissed(true)}
        />
      )}

      {/* KPI Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          title="Total Revenue"
          value={s?.totalRevenue ?? 0}
          prefix="R "
          change={s?.revenueChange}
          icon={<DollarSign size={20} />}
          variant="green"
          description="This month"
        />
        <StatCard
          title="Total Orders"
          value={s?.totalOrders ?? 0}
          change={s?.ordersChange}
          icon={<ShoppingCart size={20} />}
          description="This month"
        />
        <StatCard
          title="Active Products"
          value={s?.activeProducts ?? 0}
          icon={<Package size={20} />}
          description="In marketplace"
        />
        <StatCard
          title="Avg Order Value"
          value={s?.avgOrderValue ?? 0}
          prefix="R "
          icon={<TrendingUp size={20} />}
          variant="amber"
          description="Per order"
        />
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-4 gap-3">
        {quickActions.map(({ label, icon: Icon, to, color }) => (
          <button
            key={label}
            onClick={() => navigate(to)}
            className={`flex items-center gap-3 p-4 rounded-2xl font-semibold text-sm transition-all hover:scale-[1.02] active:scale-[0.98] border hover:shadow-card-hover ${color}`}
          >
            <div className="p-1.5 bg-white/60 rounded-lg">
              <Icon size={16} />
            </div>
            {label}
          </button>
        ))}
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-3 gap-4">
        {/* Revenue Chart */}
        <div className="card p-5 col-span-2">
          <div className="flex items-center justify-between mb-5">
            <div>
              <h3 className="font-bold text-gray-900">Revenue Trend</h3>
              <p className="text-xs text-gray-400 mt-0.5">Last 6 months performance</p>
            </div>
            <div className="flex items-center gap-2">
              <span className="metric-up">
                <ArrowUpRight size={11} /> {s && s.revenueChange >= 0 ? '+' : ''}{s?.revenueChange ?? 0}%
              </span>
              <button
                onClick={() => navigate('/analytics')}
                className="text-xs text-primary font-semibold hover:underline flex items-center gap-1"
              >
                Full report <ArrowRight size={11} />
              </button>
            </div>
          </div>
          <ResponsiveContainer width="100%" height={220}>
            <AreaChart data={revenue}>
              <defs>
                <linearGradient id="revGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#1B4332" stopOpacity={0.12} />
                  <stop offset="95%" stopColor="#1B4332" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" />
              <XAxis dataKey="month" tick={{ fontSize: 11, fill: '#9CA3AF' }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: '#9CA3AF' }} axisLine={false} tickLine={false} tickFormatter={(v) => `R${(v / 1000).toFixed(0)}k`} />
              <Tooltip
                contentStyle={{ borderRadius: '14px', border: '1px solid #E5E7EB', boxShadow: '0 8px 24px rgba(0,0,0,0.08)', fontSize: '13px' }}
                formatter={(v: number) => [`R${v.toLocaleString()}`, 'Revenue']}
              />
              <Area type="monotone" dataKey="revenue" stroke="#1B4332" fill="url(#revGrad)" strokeWidth={2.5} dot={false} activeDot={{ r: 5, fill: '#1B4332', strokeWidth: 2, stroke: '#fff' }} />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Order Pipeline */}
        <div className="card p-5">
          <div className="flex items-center justify-between mb-5">
            <h3 className="font-bold text-gray-900">Order Pipeline</h3>
            <span className="text-xs font-bold text-gray-400">{pipelineTotal} total</span>
          </div>
          <div className="space-y-3.5">
            {orderTimeline.map(({ label, count, color }) => (
              <div key={label} className="flex items-center gap-3">
                <div className={`w-2.5 h-2.5 rounded-full flex-shrink-0 ${color}`} />
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between mb-1.5">
                    <p className="text-xs font-semibold text-gray-600 truncate">{label}</p>
                    <span className="text-xs font-black text-gray-900 ml-2 tabular-nums">{count}</span>
                  </div>
                  <div className="h-1.5 bg-gray-100 rounded-full overflow-hidden">
                    <div
                      className={`h-full rounded-full ${color} transition-all duration-700`}
                      style={{ width: `${pipelineTotal > 0 ? (count / pipelineTotal) * 100 : 0}%` }}
                    />
                  </div>
                </div>
              </div>
            ))}
          </div>

          <div className="mt-5 pt-4 border-t border-gray-100">
            <div className="flex items-center gap-2 text-sm">
              <Clock size={13} className="text-amber-500" />
              <span className="text-gray-600 font-semibold text-xs">{pendingCount} order{pendingCount !== 1 ? 's' : ''} need action</span>
            </div>
            <button onClick={() => navigate('/orders')} className="mt-2 text-xs text-primary font-bold hover:underline flex items-center gap-1">
              Review pending <ArrowRight size={11} />
            </button>
          </div>
        </div>
      </div>

      {/* Bottom Row */}
      <div className="grid grid-cols-3 gap-4">
        {/* Top Products */}
        <div className="card p-5">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold text-gray-900">Top Products</h3>
            <button onClick={() => navigate('/products')} className="text-xs text-primary font-semibold hover:underline">View all</button>
          </div>
          <ResponsiveContainer width="100%" height={180}>
            <BarChart data={topProducts} layout="vertical">
              <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" horizontal={false} />
              <XAxis type="number" tick={{ fontSize: 10, fill: '#9CA3AF' }} axisLine={false} tickLine={false} />
              <YAxis type="category" dataKey="productName" tick={{ fontSize: 10, fill: '#6B7280' }} width={85} axisLine={false} tickLine={false} />
              <Tooltip
                contentStyle={{ borderRadius: '12px', border: '1px solid #E5E7EB', fontSize: '12px' }}
                formatter={(v: number) => [v, 'Units Sold']}
              />
              <Bar dataKey="totalSold" fill="#2E7D52" radius={[0, 6, 6, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Recent Orders */}
        <div className="card col-span-2">
          <SectionHeader
            title="Recent Orders"
            action={
              <button onClick={() => navigate('/orders')} className="text-sm text-primary font-semibold hover:underline flex items-center gap-1">
                View all <ArrowRight size={13} />
              </button>
            }
          />
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-50 bg-gray-50/60">
                  <th className="table-header">Order #</th>
                  <th className="table-header">Shop</th>
                  <th className="table-header text-right">Total</th>
                  <th className="table-header text-center">Status</th>
                  <th className="table-header">Date</th>
                </tr>
              </thead>
              <tbody>
                {recentOrders.map((order) => (
                  <tr key={order.id} className="table-row cursor-pointer" onClick={() => navigate('/orders')}>
                    <td className="table-cell font-bold text-primary">{order.orderNumber}</td>
                    <td className="table-cell">
                      <div>
                        <p className="font-semibold text-gray-900">{order.shopName}</p>
                        <p className="text-xs text-gray-400">{order.shopAddress}</p>
                      </div>
                    </td>
                    <td className="table-cell text-right font-black text-gray-900 tabular-nums">R{order.total.toLocaleString()}</td>
                    <td className="table-cell text-center"><OrderStatusBadge status={order.status} /></td>
                    <td className="table-cell text-gray-400 text-xs">{format(new Date(order.createdAt), 'dd MMM yyyy')}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Compliance Status */}
      <div className="card p-5">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h3 className="font-bold text-gray-900">Compliance Status</h3>
            <p className="text-xs text-gray-400 mt-0.5">Keep your documents up to date to avoid restrictions</p>
          </div>
          <button onClick={() => navigate('/profile')} className="text-sm text-primary font-semibold hover:underline flex items-center gap-1">
            Manage <ArrowRight size={13} />
          </button>
        </div>
        <div className="grid grid-cols-4 gap-3">
          {DOC_META.map(({ docType, label }) => {
            const doc = docs.find((d) => d.docType === docType);
            const status = doc?.status ?? 'missing';
            const expiry = doc?.expiryDate ? format(new Date(doc.expiryDate), 'dd MMM yyyy') : null;
            return (
            <div
              key={docType}
              className={`p-4 rounded-xl border-2 transition-all hover:shadow-card-hover cursor-default ${
                status === 'approved' ? 'bg-emerald-50 border-emerald-100' :
                status === 'pending'  ? 'bg-amber-50 border-amber-100' :
                'bg-gray-50 border-gray-100'
              }`}
            >
              <div className="flex items-center gap-2 mb-2">
                {status === 'approved' ? <CheckCircle size={15} className="text-emerald-600" /> :
                 status === 'pending'  ? <Clock size={15} className="text-amber-500 animate-pulse-soft" /> :
                 <AlertTriangle size={15} className="text-gray-400" />}
                <span className={`text-xs font-bold capitalize ${
                  status === 'approved' ? 'text-emerald-700' :
                  status === 'pending'  ? 'text-amber-700' :
                  'text-gray-500'
                }`}>{status === 'missing' ? 'Not Uploaded' : status}</span>
              </div>
              <p className="text-xs font-bold text-gray-800">{label}</p>
              {expiry && <p className="text-[10px] text-gray-400 mt-0.5">Expires {expiry}</p>}
            </div>
            );
          })}
        </div>
      </div>

      {/* Upgrade CTA Banner */}
      <div className="rounded-2xl bg-gradient-to-r from-primary-700 via-primary-600 to-primary-500 p-5 flex items-center justify-between relative overflow-hidden shadow-card-lg">
        <div className="absolute right-0 top-0 w-48 h-full bg-white/5 skew-x-12 pointer-events-none" />
        <div className="relative z-10 flex items-center gap-4">
          <div className="w-10 h-10 bg-accent/20 rounded-xl flex items-center justify-center flex-shrink-0">
            <Zap size={20} className="text-accent" />
          </div>
          <div>
            <p className="font-black text-white text-sm">Upgrade to Gold — Save R1,462/month in commission</p>
            <p className="text-green-200 text-xs mt-0.5">At your current volume, Gold tier (2%) saves you significantly vs Silver (3%)</p>
          </div>
        </div>
        <button
          onClick={() => navigate('/subscription')}
          className="relative z-10 flex items-center gap-2 bg-accent hover:bg-accent-600 text-white text-sm font-bold px-5 py-2.5 rounded-xl transition-all shadow-glow-accent flex-shrink-0"
        >
          Upgrade Now <ArrowRight size={14} />
        </button>
      </div>
    </div>
  );
}
