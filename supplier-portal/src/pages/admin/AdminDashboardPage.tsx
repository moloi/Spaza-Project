import { useNavigate } from 'react-router-dom';
import {
  Users, ShieldCheck, Package, ShoppingCart, DollarSign,
  AlertTriangle, CheckCircle, Clock, ArrowRight, TrendingUp, FileText,
} from 'lucide-react';
import { mockAdminStats, mockAdminSuppliers } from '../../services/mockData';
import { format } from 'date-fns';

const kpiCards = [
  { label: 'Total Suppliers',       value: mockAdminStats.totalSuppliers,       icon: Users,       color: 'bg-blue-50 text-blue-600',    ring: 'ring-blue-100' },
  { label: 'Pending Verifications', value: mockAdminStats.pendingVerifications,  icon: ShieldCheck, color: 'bg-amber-50 text-amber-600',  ring: 'ring-amber-100', urgent: true },
  { label: 'Pending Documents',     value: mockAdminStats.pendingDocuments,      icon: FileText,    color: 'bg-orange-50 text-orange-600', ring: 'ring-orange-100', urgent: true },
  { label: 'Active Products',       value: mockAdminStats.activeProducts,        icon: Package,     color: 'bg-emerald-50 text-emerald-600', ring: 'ring-emerald-100' },
  { label: 'Total Orders',          value: mockAdminStats.totalOrders,           icon: ShoppingCart, color: 'bg-violet-50 text-violet-600', ring: 'ring-violet-100' },
  { label: 'Platform Revenue',      value: `R${(mockAdminStats.totalRevenue / 1000).toFixed(0)}k`, icon: DollarSign, color: 'bg-primary-50 text-primary', ring: 'ring-primary-100' },
];

export default function AdminDashboardPage() {
  const navigate = useNavigate();
  const pendingSuppliers = mockAdminSuppliers.filter((s) => !s.isVerified);
  const pendingDocs = mockAdminSuppliers.flatMap((s) =>
    s.documents.filter((d) => d.status === 'pending').map((d) => ({ ...d, supplier: s.companyName, supplierId: s.id }))
  );

  return (
    <div className="p-6 space-y-6 animate-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="page-title">Admin Dashboard</h1>
          <p className="page-subtitle">{format(new Date(), 'EEEE, d MMMM yyyy')} · Platform overview</p>
        </div>
      </div>

      {/* KPI Grid */}
      <div className="grid grid-cols-2 lg:grid-cols-3 gap-4">
        {kpiCards.map(({ label, value, icon: Icon, color, ring, urgent }) => (
          <div key={label} className={`card p-5 hover:shadow-card-hover transition-shadow ${urgent ? 'border-amber-200' : ''}`}>
            <div className="flex items-start justify-between">
              <div>
                <p className="text-xs font-bold text-gray-400 uppercase tracking-wider">{label}</p>
                <p className="text-3xl font-black text-gray-900 mt-1.5 tabular-nums">{value}</p>
                {urgent && (
                  <span className="inline-flex items-center gap-1 text-[10px] font-bold text-amber-700 bg-amber-50 border border-amber-200 px-2 py-0.5 rounded-full mt-2">
                    <AlertTriangle size={9} /> Needs attention
                  </span>
                )}
              </div>
              <div className={`p-2.5 rounded-xl ring-1 ${color} ${ring}`}>
                <Icon size={20} />
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Two column row */}
      <div className="grid grid-cols-2 gap-5">
        {/* Suppliers Awaiting Verification */}
        <div className="card">
          <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100">
            <div>
              <h3 className="font-bold text-gray-900">Awaiting Verification</h3>
              <p className="text-xs text-gray-400 mt-0.5">{pendingSuppliers.length} supplier{pendingSuppliers.length !== 1 ? 's' : ''} pending</p>
            </div>
            <button onClick={() => navigate('/admin/suppliers')} className="text-sm text-blue-600 font-semibold hover:underline flex items-center gap-1">
              View all <ArrowRight size={13} />
            </button>
          </div>
          <div className="divide-y divide-gray-50">
            {pendingSuppliers.length === 0 ? (
              <div className="p-8 text-center">
                <CheckCircle size={28} className="text-emerald-400 mx-auto mb-2" />
                <p className="text-sm font-semibold text-gray-600">All suppliers verified</p>
              </div>
            ) : pendingSuppliers.map((s) => (
              <div key={s.id} className="flex items-center justify-between px-5 py-3.5 hover:bg-gray-50/60 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-xl bg-slate-100 flex items-center justify-center font-bold text-slate-600 text-sm flex-shrink-0">
                    {s.companyName.charAt(0)}
                  </div>
                  <div>
                    <p className="text-sm font-semibold text-gray-900">{s.companyName}</p>
                    <p className="text-xs text-gray-400">{s.email}</p>
                  </div>
                </div>
                <button
                  onClick={() => navigate('/admin/documents')}
                  className="text-xs font-bold text-blue-600 bg-blue-50 border border-blue-200 px-3 py-1.5 rounded-lg hover:bg-blue-100 transition-colors"
                >
                  Review
                </button>
              </div>
            ))}
          </div>
        </div>

        {/* Pending Documents */}
        <div className="card">
          <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100">
            <div>
              <h3 className="font-bold text-gray-900">Pending Documents</h3>
              <p className="text-xs text-gray-400 mt-0.5">{pendingDocs.length} document{pendingDocs.length !== 1 ? 's' : ''} to review</p>
            </div>
            <button onClick={() => navigate('/admin/documents')} className="text-sm text-blue-600 font-semibold hover:underline flex items-center gap-1">
              Review all <ArrowRight size={13} />
            </button>
          </div>
          <div className="divide-y divide-gray-50">
            {pendingDocs.slice(0, 5).map((doc, i) => (
              <div key={i} className="flex items-center justify-between px-5 py-3.5 hover:bg-gray-50/60 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg bg-amber-50 border border-amber-100 flex items-center justify-center flex-shrink-0">
                    <FileText size={14} className="text-amber-600" />
                  </div>
                  <div>
                    <p className="text-sm font-semibold text-gray-900">{doc.label}</p>
                    <p className="text-xs text-gray-400">{doc.supplier}</p>
                  </div>
                </div>
                <div className="flex items-center gap-1.5">
                  <Clock size={12} className="text-amber-500" />
                  <span className="text-xs font-semibold text-amber-700">Pending</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* All Suppliers Table */}
      <div className="card">
        <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100">
          <h3 className="font-bold text-gray-900">All Suppliers</h3>
          <button onClick={() => navigate('/admin/suppliers')} className="text-sm text-blue-600 font-semibold hover:underline flex items-center gap-1">
            Manage <ArrowRight size={13} />
          </button>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-50 bg-gray-50/60">
                <th className="table-header">Company</th>
                <th className="table-header">Tier</th>
                <th className="table-header text-right">Orders</th>
                <th className="table-header text-right">Revenue</th>
                <th className="table-header text-center">Status</th>
                <th className="table-header">Joined</th>
              </tr>
            </thead>
            <tbody>
              {mockAdminSuppliers.map((s) => (
                <tr key={s.id} className="table-row cursor-pointer" onClick={() => navigate('/admin/suppliers')}>
                  <td className="table-cell">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-lg bg-slate-100 flex items-center justify-center font-bold text-slate-600 text-xs flex-shrink-0">
                        {s.companyName.charAt(0)}
                      </div>
                      <div>
                        <p className="font-semibold text-gray-900">{s.companyName}</p>
                        <p className="text-xs text-gray-400">{s.email}</p>
                      </div>
                    </div>
                  </td>
                  <td className="table-cell">
                    <span className="text-xs font-bold capitalize px-2.5 py-1 rounded-full bg-gray-100 text-gray-600">{s.tier}</span>
                  </td>
                  <td className="table-cell text-right font-bold tabular-nums">{s.totalOrders}</td>
                  <td className="table-cell text-right font-bold text-emerald-700 tabular-nums">R{s.totalRevenue.toLocaleString()}</td>
                  <td className="table-cell text-center">
                    {s.isVerified ? (
                      <span className="inline-flex items-center gap-1 text-xs font-bold text-emerald-700 bg-emerald-50 border border-emerald-200 px-2.5 py-1 rounded-full">
                        <CheckCircle size={11} /> Verified
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 text-xs font-bold text-amber-700 bg-amber-50 border border-amber-200 px-2.5 py-1 rounded-full">
                        <Clock size={11} /> Pending
                      </span>
                    )}
                  </td>
                  <td className="table-cell text-xs text-gray-400">{format(new Date(s.joinedAt), 'dd MMM yyyy')}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
