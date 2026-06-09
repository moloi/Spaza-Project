import { useState } from 'react';
import { DollarSign, ShoppingCart, Users, Package, TrendingUp, Download, ArrowUpRight } from 'lucide-react';
import {
  AreaChart, Area, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, PieChart, Pie, Cell, Legend,
} from 'recharts';
import { mockAdminRevenue, mockAdminStats, mockAdminSuppliers } from '../../services/mockData';
import toast from 'react-hot-toast';

const COLORS = ['#1B4332', '#2E7D52', '#4CAF50', '#81C784', '#A5D6A7'];

const ordersByStatus = [
  { name: 'Delivered',  value: 412 },
  { name: 'Processing', value: 89 },
  { name: 'Dispatched', value: 45 },
  { name: 'Cancelled',  value: 32 },
];

const feeIncome = mockAdminRevenue.map((r) => ({ ...r, fees: Math.round(r.revenue * 0.035) }));

const CustomTooltip = ({ active, payload, label }: any) => {
  if (!active || !payload?.length) return null;
  return (
    <div className="bg-white border border-gray-100 rounded-xl shadow-card-lg p-3 text-sm">
      <p className="font-bold text-gray-700 mb-1">{label}</p>
      {payload.map((p: any) => (
        <p key={p.name} style={{ color: p.color }} className="font-semibold">
          {p.name === 'revenue' || p.name === 'fees' ? `R${p.value.toLocaleString()}` : p.value} {p.name}
        </p>
      ))}
    </div>
  );
};

export default function AdminAnalyticsPage() {
  const [period, setPeriod] = useState<'week' | 'month' | 'year'>('month');

  const totalFees = feeIncome.reduce((s, r) => s + r.fees, 0);
  const topSupplier = [...mockAdminSuppliers].sort((a, b) => b.totalRevenue - a.totalRevenue)[0];

  return (
    <div className="p-6 space-y-6 animate-in">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="page-title">Platform Analytics</h1>
          <p className="page-subtitle">Full platform performance overview</p>
        </div>
        <button onClick={() => toast.success('Report export started')} className="btn-secondary flex items-center gap-2">
          <Download size={15} /> Export Report
        </button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'Platform GMV',     value: `R${(mockAdminStats.totalRevenue / 1000).toFixed(0)}k`, icon: <DollarSign size={20} />, color: 'stat-card-green', change: '+18.4%' },
          { label: 'Total Orders',     value: mockAdminStats.totalOrders,  icon: <ShoppingCart size={20} />, color: 'card p-5', change: '+12.1%' },
          { label: 'Active Suppliers', value: mockAdminStats.totalSuppliers, icon: <Users size={20} />,       color: 'card p-5', change: '+2 this month' },
          { label: 'Fee Income',       value: `R${(totalFees / 1000).toFixed(1)}k`, icon: <TrendingUp size={20} />, color: 'stat-card-amber', change: '+18.4%' },
        ].map(({ label, value, icon, color, change }) => (
          <div key={label} className={`${color} animate-in`}>
            <div className="flex items-start justify-between">
              <div>
                <p className="text-xs font-bold uppercase tracking-wider opacity-70">{label}</p>
                <p className="text-3xl font-black mt-1.5 tabular-nums">{value}</p>
                <span className="inline-flex items-center gap-1 text-xs font-bold mt-2 opacity-80">
                  <ArrowUpRight size={11} /> {change}
                </span>
              </div>
              <div className="p-2.5 bg-white/15 rounded-xl ring-1 ring-white/10">{icon}</div>
            </div>
          </div>
        ))}
      </div>

      {/* Period Toggle */}
      <div className="flex items-center gap-1.5 bg-white border border-gray-200 rounded-xl p-1 w-fit">
        {(['week', 'month', 'year'] as const).map((p) => (
          <button key={p} onClick={() => setPeriod(p)}
            className={`px-4 py-1.5 rounded-lg text-sm font-semibold capitalize transition-all ${period === p ? 'bg-slate-800 text-white shadow-sm' : 'text-gray-500 hover:text-gray-700'}`}>
            {p}
          </button>
        ))}
      </div>

      {/* Charts Row 1 */}
      <div className="grid grid-cols-3 gap-4">
        <div className="card p-5 col-span-2">
          <div className="flex items-center justify-between mb-5">
            <div>
              <h3 className="font-bold text-gray-900">Platform GMV Trend</h3>
              <p className="text-xs text-gray-400 mt-0.5">Total gross merchandise value</p>
            </div>
            <span className="metric-up"><ArrowUpRight size={11} /> +18.4%</span>
          </div>
          <ResponsiveContainer width="100%" height={240}>
            <AreaChart data={mockAdminRevenue}>
              <defs>
                <linearGradient id="adminGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#1E293B" stopOpacity={0.12} />
                  <stop offset="95%" stopColor="#1E293B" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" />
              <XAxis dataKey="month" tick={{ fontSize: 11, fill: '#9CA3AF' }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: '#9CA3AF' }} axisLine={false} tickLine={false} tickFormatter={(v) => `R${(v / 1000).toFixed(0)}k`} />
              <Tooltip content={<CustomTooltip />} />
              <Area type="monotone" dataKey="revenue" stroke="#1E293B" fill="url(#adminGrad)" strokeWidth={2.5} dot={false} activeDot={{ r: 5, fill: '#1E293B', strokeWidth: 2, stroke: '#fff' }} />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        <div className="card p-5">
          <h3 className="font-bold text-gray-900 mb-5">Orders by Status</h3>
          <ResponsiveContainer width="100%" height={240}>
            <PieChart>
              <Pie data={ordersByStatus} cx="50%" cy="45%" innerRadius={55} outerRadius={85} dataKey="value" paddingAngle={3}>
                {ordersByStatus.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
              </Pie>
              <Tooltip contentStyle={{ borderRadius: '12px', border: '1px solid #E5E7EB', fontSize: '12px' }} />
              <Legend iconType="circle" iconSize={8} wrapperStyle={{ fontSize: '12px' }} />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Charts Row 2 */}
      <div className="grid grid-cols-2 gap-4">
        <div className="card p-5">
          <h3 className="font-bold text-gray-900 mb-5">Monthly Orders</h3>
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={mockAdminRevenue}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" />
              <XAxis dataKey="month" tick={{ fontSize: 11, fill: '#9CA3AF' }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: '#9CA3AF' }} axisLine={false} tickLine={false} />
              <Tooltip content={<CustomTooltip />} />
              <Bar dataKey="orders" fill="#1E293B" radius={[6, 6, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className="card p-5">
          <h3 className="font-bold text-gray-900 mb-5">Platform Fee Income</h3>
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={feeIncome}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" />
              <XAxis dataKey="month" tick={{ fontSize: 11, fill: '#9CA3AF' }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: '#9CA3AF' }} axisLine={false} tickLine={false} tickFormatter={(v) => `R${(v / 1000).toFixed(0)}k`} />
              <Tooltip content={<CustomTooltip />} />
              <Bar dataKey="fees" fill="#7C3AED" radius={[6, 6, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Supplier Revenue Breakdown */}
      <div className="card p-5">
        <h3 className="font-bold text-gray-900 mb-4">Supplier Revenue Breakdown</h3>
        <div className="space-y-4">
          {[...mockAdminSuppliers].sort((a, b) => b.totalRevenue - a.totalRevenue).map((s, i) => (
            <div key={s.id}>
              <div className="flex items-center justify-between mb-1.5">
                <div className="flex items-center gap-2">
                  <span className={`w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-black text-white ${i === 0 ? 'bg-amber-500' : i === 1 ? 'bg-gray-400' : 'bg-orange-400'}`}>{i + 1}</span>
                  <span className="text-sm font-semibold text-gray-900">{s.companyName}</span>
                  <span className="text-xs text-gray-400">({s.totalOrders} orders)</span>
                </div>
                <span className="font-bold text-gray-700 tabular-nums">R{s.totalRevenue.toLocaleString()}</span>
              </div>
              <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                <div
                  className="h-full rounded-full bg-gradient-to-r from-slate-700 to-slate-500 transition-all duration-700"
                  style={{ width: `${(s.totalRevenue / topSupplier.totalRevenue) * 100}%` }}
                />
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
