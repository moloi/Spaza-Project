import { useState } from 'react';
import { Search, Eye, CheckCircle, XCircle, Truck, ShoppingCart, Clock, Package, DollarSign } from 'lucide-react';
import toast from 'react-hot-toast';
import { format } from 'date-fns';
import clsx from 'clsx';
import { mockOrders } from '../../services/mockData';
import type { Order, OrderStatus } from '../../types';
import { OrderStatusBadge, PaymentStatusBadge } from '../../components/ui';
import OrderDetailModal from '../orders/OrderDetailModal';

const statusTabs = [
  { value: 'all',        label: 'All Orders' },
  { value: 'pending',    label: 'Pending' },
  { value: 'processing', label: 'Processing' },
  { value: 'dispatched', label: 'Dispatched' },
  { value: 'delivered',  label: 'Delivered' },
  { value: 'cancelled',  label: 'Cancelled' },
];

export default function AdminOrdersPage() {
  const [orders, setOrders] = useState<Order[]>(mockOrders);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selected, setSelected] = useState<Order | null>(null);

  const filtered = orders.filter((o) => {
    const matchSearch = o.orderNumber.toLowerCase().includes(search.toLowerCase()) ||
                        o.shopName.toLowerCase().includes(search.toLowerCase());
    const matchStatus = statusFilter === 'all' || o.status === statusFilter;
    return matchSearch && matchStatus;
  });

  const updateStatus = (id: string, status: OrderStatus) => {
    setOrders((prev) => prev.map((o) => o.id === id ? { ...o, status } : o));
    toast.success(`Order status updated to ${status}`);
    if (selected?.id === id) setSelected((prev) => prev ? { ...prev, status } : null);
  };

  const totalRevenue   = orders.filter((o) => o.status === 'delivered').reduce((s, o) => s + o.total, 0);
  const platformFees   = orders.reduce((s, o) => s + o.platformFee, 0);
  const pendingCount   = orders.filter((o) => o.status === 'pending').length;
  const disputedCount  = orders.filter((o) => o.status === 'disputed').length;

  return (
    <div className="p-6 space-y-5 animate-in">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="page-title">Orders</h1>
          <p className="page-subtitle">All platform orders across all suppliers and spaza shops</p>
        </div>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-4 gap-4">
        <div className="card p-4 flex items-center gap-3">
          <div className="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center flex-shrink-0"><ShoppingCart size={18} className="text-blue-600" /></div>
          <div><p className="text-2xl font-black tabular-nums">{orders.length}</p><p className="text-xs text-gray-500 font-semibold">Total Orders</p></div>
        </div>
        <div className="card p-4 flex items-center gap-3">
          <div className="w-10 h-10 bg-amber-50 rounded-xl flex items-center justify-center flex-shrink-0"><Clock size={18} className="text-amber-600" /></div>
          <div><p className="text-2xl font-black tabular-nums">{pendingCount}</p><p className="text-xs text-gray-500 font-semibold">Pending</p></div>
        </div>
        <div className="card p-4 flex items-center gap-3">
          <div className="w-10 h-10 bg-emerald-50 rounded-xl flex items-center justify-center flex-shrink-0"><DollarSign size={18} className="text-emerald-600" /></div>
          <div><p className="text-2xl font-black tabular-nums">R{(totalRevenue / 1000).toFixed(1)}k</p><p className="text-xs text-gray-500 font-semibold">GMV Delivered</p></div>
        </div>
        <div className="card p-4 flex items-center gap-3">
          <div className="w-10 h-10 bg-violet-50 rounded-xl flex items-center justify-center flex-shrink-0"><DollarSign size={18} className="text-violet-600" /></div>
          <div><p className="text-2xl font-black tabular-nums">R{platformFees.toFixed(0)}</p><p className="text-xs text-gray-500 font-semibold">Platform Fees</p></div>
        </div>
      </div>

      {/* Status Tabs */}
      <div className="flex items-center gap-0.5 border-b border-gray-200 overflow-x-auto">
        {statusTabs.map(({ value, label }) => {
          const count = value === 'all' ? orders.length : orders.filter((o) => o.status === value).length;
          return (
            <button key={value} onClick={() => setStatusFilter(value)}
              className={clsx('flex items-center gap-1.5 px-4 py-3 text-sm font-semibold border-b-2 transition-all whitespace-nowrap',
                statusFilter === value ? 'border-slate-800 text-slate-900' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              )}>
              {label}
              {count > 0 && (
                <span className={clsx('text-[10px] font-black px-1.5 py-0.5 rounded-full min-w-[18px] text-center',
                  statusFilter === value ? 'bg-slate-800 text-white' : 'bg-gray-100 text-gray-600'
                )}>{count}</span>
              )}
            </button>
          );
        })}
      </div>

      {/* Search */}
      <div className="relative max-w-sm">
        <Search size={14} className="absolute left-3.5 top-3 text-gray-400" />
        <input value={search} onChange={(e) => setSearch(e.target.value)} className="input pl-10" placeholder="Search order # or shop name..." />
      </div>

      {/* Table */}
      <div className="card overflow-hidden">
        {filtered.length === 0 ? (
          <div className="p-16 text-center">
            <ShoppingCart size={36} className="text-gray-200 mx-auto mb-3" />
            <p className="font-bold text-gray-600">No orders found</p>
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 bg-gray-50/60">
                <th className="table-header">Order #</th>
                <th className="table-header">Shop</th>
                <th className="table-header">Supplier</th>
                <th className="table-header text-right">Total</th>
                <th className="table-header text-right">Platform Fee</th>
                <th className="table-header text-center">Status</th>
                <th className="table-header text-center">Payment</th>
                <th className="table-header">Date</th>
                <th className="table-header text-center">Actions</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((order) => (
                <tr key={order.id} className="table-row">
                  <td className="table-cell">
                    <button onClick={() => setSelected(order)} className="font-bold text-blue-600 hover:underline">{order.orderNumber}</button>
                  </td>
                  <td className="table-cell">
                    <p className="font-semibold text-gray-900">{order.shopName}</p>
                    <p className="text-xs text-gray-400">{order.shopAddress}</p>
                  </td>
                  <td className="table-cell text-xs text-gray-500 font-semibold">
                    {order.items[0]?.productName ? 'Fresh Foods SA' : '—'}
                  </td>
                  <td className="table-cell text-right font-black tabular-nums">R{order.total.toLocaleString()}</td>
                  <td className="table-cell text-right font-semibold text-violet-700 tabular-nums">R{order.platformFee.toFixed(2)}</td>
                  <td className="table-cell text-center"><OrderStatusBadge status={order.status} /></td>
                  <td className="table-cell text-center"><PaymentStatusBadge status={order.paymentStatus} /></td>
                  <td className="table-cell text-xs text-gray-400">
                    <p>{format(new Date(order.createdAt), 'dd MMM yyyy')}</p>
                    <p>{format(new Date(order.createdAt), 'HH:mm')}</p>
                  </td>
                  <td className="table-cell">
                    <div className="flex items-center justify-center gap-1">
                      <button onClick={() => setSelected(order)} className="p-2 rounded-lg text-gray-400 hover:text-blue-600 hover:bg-blue-50 transition-all" title="View">
                        <Eye size={14} />
                      </button>
                      {order.status === 'pending' && (
                        <>
                          <button onClick={() => updateStatus(order.id, 'processing')} className="p-2 rounded-lg text-gray-400 hover:text-emerald-600 hover:bg-emerald-50 transition-all" title="Accept">
                            <CheckCircle size={14} />
                          </button>
                          <button onClick={() => updateStatus(order.id, 'cancelled')} className="p-2 rounded-lg text-gray-400 hover:text-red-500 hover:bg-red-50 transition-all" title="Cancel">
                            <XCircle size={14} />
                          </button>
                        </>
                      )}
                      {order.status === 'processing' && (
                        <button onClick={() => updateStatus(order.id, 'dispatched')} className="p-2 rounded-lg text-gray-400 hover:text-indigo-600 hover:bg-indigo-50 transition-all" title="Mark Dispatched">
                          <Truck size={14} />
                        </button>
                      )}
                      {order.status === 'dispatched' && (
                        <button onClick={() => updateStatus(order.id, 'delivered')} className="p-2 rounded-lg text-gray-400 hover:text-emerald-600 hover:bg-emerald-50 transition-all" title="Mark Delivered">
                          <CheckCircle size={14} />
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {selected && <OrderDetailModal order={selected} onClose={() => setSelected(null)} onUpdateStatus={updateStatus} />}
    </div>
  );
}
