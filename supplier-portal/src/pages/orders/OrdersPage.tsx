import { useState, useEffect } from 'react';
import { Search, Eye, CheckCircle, XCircle, Truck, ShoppingCart, Clock, Package, DollarSign } from 'lucide-react';
import toast from 'react-hot-toast';
import { format } from 'date-fns';
import { ordersApi } from '../../services/api';
import type { Order, OrderStatus } from '../../types';
import { OrderStatusBadge, PaymentStatusBadge, EmptyState } from '../../components/ui';
import PageLoader from '../../components/ui/PageLoader';
import clsx from 'clsx';
import OrderDetailModal from './OrderDetailModal';
import { useOrderStore } from '../../store/orderStore';

const STATUS_TABS: { value: string; label: string }[] = [
  { value: 'all',        label: 'All Orders'  },
  { value: 'pending',    label: 'Pending'     },
  { value: 'processing', label: 'Processing'  },
  { value: 'dispatched', label: 'Dispatched'  },
  { value: 'delivered',  label: 'Delivered'   },
  { value: 'cancelled',  label: 'Cancelled'   },
];

function mapOrder(o: any): Order {
  return {
    id:             o.id,
    orderNumber:    o.orderNumber,
    shopId:         o.shop?.id ?? '',
    shopName:       o.shop?.shopName ?? '',
    shopAddress:    o.shop?.address ?? '',
    items: (o.items ?? []).map((i: any) => ({
      productId:    i.productId,
      productName:  i.name,
      productImage: '',
      quantity:     i.quantity,
      price:        i.unitPrice,
    })),
    subtotal:       o.items?.reduce((s: number, i: any) => s + i.lineTotal, 0) ?? 0,
    deliveryFee:    0,
    platformFee:    0,
    total:          o.totalAmount ?? 0,
    status:         o.status,
    deliveryOption: o.deliveryType ?? 'standard',
    paymentMethod:  'eft',
    paymentStatus:  'held',
    createdAt:      o.createdAt,
    estimatedDelivery: o.estimatedDelivery,
  };
}

export default function OrdersPage() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selected, setSelected] = useState<Order | null>(null);
  const [loading, setLoading] = useState(true);
  const { fetchPendingCount } = useOrderStore();

  useEffect(() => {
    ordersApi.list({ pageSize: 100 })
      .then((res: any) => {
        const raw = res?.data?.items ?? res?.items ?? [];
        setOrders(raw.map(mapOrder));
      })
      .catch(() => toast.error('Failed to load orders.'))
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <PageLoader variant="table" />;

  const filtered = orders.filter((o) => {
    const matchSearch = o.orderNumber.toLowerCase().includes(search.toLowerCase()) || o.shopName.toLowerCase().includes(search.toLowerCase());
    const matchStatus = statusFilter === 'all' || o.status === statusFilter;
    return matchSearch && matchStatus;
  });

  const updateStatus = async (id: string, status: OrderStatus) => {
    try {
      await ordersApi.updateStatus(id, status);
      setOrders((prev) => prev.map((o) => o.id === id ? { ...o, status } : o));
      toast.success(`Order ${status}`);
      if (selected?.id === id) setSelected((prev) => prev ? { ...prev, status } : null);
      // Refresh the sidebar badge count immediately
      useOrderStore.setState({ lastFetched: 0 });
      fetchPendingCount();
    } catch {
      // error toast handled by api interceptor
    }
  };

  const totalRevenue = orders.filter((o) => o.status === 'delivered').reduce((s, o) => s + o.total, 0);
  const pendingCount = orders.filter((o) => o.status === 'pending').length;
  const processingCount = orders.filter((o) => o.status === 'processing').length;

  return (
    <div className="p-6 space-y-5 animate-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="page-title">Orders</h1>
          <p className="page-subtitle">{orders.length} total orders</p>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-4 gap-3">
        <div className="card p-4 flex items-center gap-3">
          <div className="w-10 h-10 bg-amber-50 rounded-xl flex items-center justify-center flex-shrink-0">
            <Clock size={18} className="text-amber-600" />
          </div>
          <div>
            <p className="text-xl font-black text-gray-900">{pendingCount}</p>
            <p className="text-xs text-gray-500 font-medium">Awaiting Action</p>
          </div>
        </div>
        <div className="card p-4 flex items-center gap-3">
          <div className="w-10 h-10 bg-violet-50 rounded-xl flex items-center justify-center flex-shrink-0">
            <Package size={18} className="text-violet-600" />
          </div>
          <div>
            <p className="text-xl font-black text-gray-900">{processingCount}</p>
            <p className="text-xs text-gray-500 font-medium">In Processing</p>
          </div>
        </div>
        <div className="card p-4 flex items-center gap-3">
          <div className="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center flex-shrink-0">
            <Truck size={18} className="text-indigo-600" />
          </div>
          <div>
            <p className="text-xl font-black text-gray-900">{orders.filter((o) => o.status === 'dispatched').length}</p>
            <p className="text-xs text-gray-500 font-medium">Out for Delivery</p>
          </div>
        </div>
        <div className="card p-4 flex items-center gap-3">
          <div className="w-10 h-10 bg-emerald-50 rounded-xl flex items-center justify-center flex-shrink-0">
            <DollarSign size={18} className="text-emerald-600" />
          </div>
          <div>
            <p className="text-xl font-black text-gray-900">R{(totalRevenue / 1000).toFixed(1)}k</p>
            <p className="text-xs text-gray-500 font-medium">Revenue Delivered</p>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-0.5 border-b border-gray-200 overflow-x-auto">
        {STATUS_TABS.map(({ value, label }) => {
          const count = value === 'all' ? null : orders.filter((o) => o.status === value).length;
          return (
            <button
              key={value}
              onClick={() => setStatusFilter(value)}
              className={clsx(
                'flex items-center gap-1.5 px-4 py-3 text-sm font-semibold border-b-2 transition-all whitespace-nowrap',
                statusFilter === value
                  ? 'border-primary text-primary'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              )}
            >
              {label}
              {count !== null && count > 0 && (
                <span className={clsx('text-[10px] font-bold px-1.5 py-0.5 rounded-full min-w-[18px] text-center',
                  statusFilter === value ? 'bg-primary text-white' : 'bg-gray-100 text-gray-600'
                )}>
                  {count}
                </span>
              )}
            </button>
          );
        })}
      </div>

      {/* Search */}
      <div className="relative max-w-sm">
        <Search size={15} className="absolute left-3.5 top-3 text-gray-400" />
        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="input pl-10 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all"
          placeholder="Search order # or shop name..."
        />
        {search && (
          <button onClick={() => setSearch('')} className="absolute right-3 top-2.5 text-gray-400 hover:text-gray-600 transition-colors">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
          </button>
        )}
      </div>

      {/* Table */}
      <div className="card overflow-hidden">
        {filtered.length === 0 ? (
          <EmptyState
            title="No orders found"
            description="Orders from spaza shops will appear here once placed."
            icon={<ShoppingCart size={40} />}
          />
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 bg-gray-50/80">
                <th className="table-header">Order #</th>
                <th className="table-header">Shop</th>
                <th className="table-header">Items</th>
                <th className="table-header text-right">Total</th>
                <th className="table-header text-right">Net Payout</th>
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
                    <button onClick={() => setSelected(order)} className="font-bold text-primary hover:underline">
                      {order.orderNumber}
                    </button>
                  </td>
                  <td className="table-cell">
                    <div>
                      <p className="font-semibold text-gray-900">{order.shopName}</p>
                      <p className="text-xs text-gray-400">{order.shopAddress}</p>
                    </div>
                  </td>
                  <td className="table-cell text-gray-500">
                    {order.items.length} item{order.items.length !== 1 ? 's' : ''}
                  </td>
                  <td className="table-cell text-right font-bold text-gray-900">
                    R{order.total.toLocaleString()}
                  </td>
                  <td className="table-cell text-right font-bold text-emerald-700">
                    R{(order.total - order.platformFee - order.deliveryFee).toFixed(2)}
                  </td>
                  <td className="table-cell text-center">
                    <OrderStatusBadge status={order.status} />
                  </td>
                  <td className="table-cell text-center">
                    <PaymentStatusBadge status={order.paymentStatus} />
                  </td>
                  <td className="table-cell text-gray-400 text-xs">
                    <p>{format(new Date(order.createdAt), 'dd MMM yyyy')}</p>
                    <p>{format(new Date(order.createdAt), 'HH:mm')}</p>
                  </td>
                  <td className="table-cell">
                    <div className="flex items-center justify-center gap-1">
                      <button onClick={() => setSelected(order)} className="btn-icon hover:text-primary hover:bg-primary-50" title="View Details">
                        <Eye size={14} />
                      </button>
                      {order.status === 'pending' && (
                        <>
                          <button onClick={() => updateStatus(order.id, 'processing')} className="btn-icon hover:text-emerald-600 hover:bg-emerald-50" title="Accept Order">
                            <CheckCircle size={14} />
                          </button>
                          <button onClick={() => updateStatus(order.id, 'cancelled')} className="btn-icon hover:text-red-500 hover:bg-red-50" title="Reject Order">
                            <XCircle size={14} />
                          </button>
                        </>
                      )}
                      {order.status === 'processing' && (
                        <button onClick={() => updateStatus(order.id, 'dispatched')} className="btn-icon hover:text-indigo-600 hover:bg-indigo-50" title="Mark Dispatched">
                          <Truck size={14} />
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

      {selected && (
        <OrderDetailModal order={selected} onClose={() => setSelected(null)} onUpdateStatus={updateStatus} />
      )}
    </div>
  );
}
