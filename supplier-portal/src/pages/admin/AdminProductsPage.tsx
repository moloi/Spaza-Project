import { useState, useEffect, useCallback, useMemo } from 'react';
import {
  Search, CheckCircle, XCircle, ToggleLeft, ToggleRight, Package, Clock,
  RefreshCw, Loader2, ChevronDown, ChevronRight, Users, Layers,
} from 'lucide-react';
import toast from 'react-hot-toast';
import clsx from 'clsx';
import { format } from 'date-fns';
import { adminProductsApi } from '../../services/api';
import type { Product } from '../../types';

type StatusFilter = 'all' | 'pending_approval' | 'active' | 'archived';
type ViewMode = 'flat' | 'grouped';

const statusStyle: Record<string, string> = {
  active:           'bg-emerald-50 text-emerald-700 border-emerald-200',
  pending_approval: 'bg-amber-50 text-amber-700 border-amber-200',
  archived:         'bg-gray-100 text-gray-500 border-gray-200',
  draft:            'bg-blue-50 text-blue-700 border-blue-200',
};

const statusFilters: { value: StatusFilter; label: string }[] = [
  { value: 'all',              label: 'All' },
  { value: 'pending_approval', label: 'Pending Approval' },
  { value: 'active',           label: 'Active' },
  { value: 'archived',         label: 'Archived' },
];

interface SupplierGroup {
  supplierName: string;
  supplierId: string;
  products: Product[];
  totalRevenue: number;
  activeCount: number;
  pendingCount: number;
}

export default function AdminProductsPage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all');
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [viewMode, setViewMode] = useState<ViewMode>('grouped');
  const [expandedSuppliers, setExpandedSuppliers] = useState<Set<string>>(new Set());
  const pageSize = 50;

  const fetchProducts = useCallback(async () => {
    setLoading(true);
    try {
      const params: { page: number; pageSize: number; search?: string; status?: string } = {
        page,
        pageSize,
      };
      if (search.trim()) params.search = search.trim();
      if (statusFilter !== 'all') params.status = statusFilter;

      const result = await adminProductsApi.list(params);
      setProducts(result.data);
      setTotal(result.total);
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Failed to load products');
    } finally {
      setLoading(false);
    }
  }, [page, pageSize, search, statusFilter]);

  useEffect(() => {
    fetchProducts();
  }, [fetchProducts]);

  useEffect(() => {
    setPage(1);
  }, [search, statusFilter]);

  // Group products by supplier
  const supplierGroups = useMemo((): SupplierGroup[] => {
    const groupMap = new Map<string, SupplierGroup>();

    products.forEach((p) => {
      const key = p.supplierId || p.supplierName || 'Unknown';
      if (!groupMap.has(key)) {
        groupMap.set(key, {
          supplierId: p.supplierId || key,
          supplierName: p.supplierName || 'Unknown Supplier',
          products: [],
          totalRevenue: 0,
          activeCount: 0,
          pendingCount: 0,
        });
      }
      const group = groupMap.get(key)!;
      group.products.push(p);
      group.totalRevenue += p.price * p.stockQuantity;
      if (p.status === 'active') group.activeCount++;
      if (p.status === 'pending_approval') group.pendingCount++;
    });

    return Array.from(groupMap.values()).sort((a, b) => b.products.length - a.products.length);
  }, [products]);

  // Auto-expand all groups on load
  useEffect(() => {
    if (supplierGroups.length > 0 && expandedSuppliers.size === 0) {
      setExpandedSuppliers(new Set(supplierGroups.map((g) => g.supplierId)));
    }
  }, [supplierGroups]);

  const toggleExpanded = (supplierId: string) => {
    setExpandedSuppliers((prev) => {
      const next = new Set(prev);
      if (next.has(supplierId)) next.delete(supplierId);
      else next.add(supplierId);
      return next;
    });
  };

  const expandAll = () => setExpandedSuppliers(new Set(supplierGroups.map((g) => g.supplierId)));
  const collapseAll = () => setExpandedSuppliers(new Set());

  const approve = async (id: string) => {
    setActionLoading(id);
    try {
      await adminProductsApi.approve(id);
      toast.success('Product approved and now live');
      fetchProducts();
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Failed to approve product');
    } finally {
      setActionLoading(null);
    }
  };

  const reject = async (id: string) => {
    setActionLoading(id);
    try {
      await adminProductsApi.reject(id);
      toast.error('Product rejected and archived');
      fetchProducts();
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Failed to reject product');
    } finally {
      setActionLoading(null);
    }
  };

  const toggleAvailability = async (id: string) => {
    setActionLoading(id);
    try {
      await adminProductsApi.toggleAvailability(id);
      toast.success('Availability updated');
      fetchProducts();
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Failed to update availability');
    } finally {
      setActionLoading(null);
    }
  };

  const pendingCount = products.filter((p) => p.status === 'pending_approval').length;
  const activeCount  = products.filter((p) => p.status === 'active').length;

  const renderProductRow = (p: Product) => (
    <tr key={p.id} className="table-row">
      <td className="table-cell">
        <div className="flex items-center gap-3">
          <img src={p.imageUrl || '/placeholder-product.png'} alt={p.name} className="w-10 h-10 rounded-xl object-cover bg-gray-100 flex-shrink-0" />
          <div>
            <p className="font-semibold text-gray-900">{p.name}</p>
            <p className="text-xs text-gray-400 font-mono">{p.sku}</p>
          </div>
        </div>
      </td>
      {viewMode === 'flat' && (
        <td className="table-cell text-gray-600 text-xs font-semibold">{p.supplierName}</td>
      )}
      <td className="table-cell">
        <span className="text-xs bg-gray-100 text-gray-600 px-2 py-1 rounded-lg font-medium">{p.categoryName}</span>
      </td>
      <td className="table-cell text-right font-bold tabular-nums">R{p.price.toFixed(2)}</td>
      <td className="table-cell text-right">
        <span className={clsx('font-bold text-sm tabular-nums', p.stockQuantity === 0 ? 'text-red-500' : p.stockQuantity < 50 ? 'text-amber-600' : 'text-gray-700')}>
          {p.stockQuantity}
        </span>
      </td>
      <td className="table-cell text-center">
        <span className={clsx('text-xs font-bold px-2.5 py-1 rounded-full border capitalize', statusStyle[p.status] ?? 'bg-gray-100 text-gray-500 border-gray-200')}>
          {p.status.replace('_', ' ')}
        </span>
      </td>
      <td className="table-cell text-center">
        <button
          onClick={() => toggleAvailability(p.id)}
          disabled={actionLoading === p.id}
          className={clsx('transition-colors disabled:opacity-50', p.isAvailable ? 'text-emerald-600' : 'text-gray-300')}
        >
          {p.isAvailable ? <ToggleRight size={22} /> : <ToggleLeft size={22} />}
        </button>
      </td>
      <td className="table-cell text-xs text-gray-400">{format(new Date(p.createdAt), 'dd MMM yyyy')}</td>
      <td className="table-cell">
        <div className="flex items-center justify-center gap-1">
          {actionLoading === p.id ? (
            <Loader2 size={14} className="animate-spin text-gray-400" />
          ) : (
            <>
              {p.status === 'pending_approval' && (
                <>
                  <button onClick={() => approve(p.id)} title="Approve" className="p-2 rounded-lg text-gray-400 hover:text-emerald-600 hover:bg-emerald-50 transition-all">
                    <CheckCircle size={14} />
                  </button>
                  <button onClick={() => reject(p.id)} title="Reject" className="p-2 rounded-lg text-gray-400 hover:text-red-500 hover:bg-red-50 transition-all">
                    <XCircle size={14} />
                  </button>
                </>
              )}
              {p.status === 'active' && (
                <button onClick={() => reject(p.id)} title="Archive" className="p-2 rounded-lg text-gray-400 hover:text-red-500 hover:bg-red-50 transition-all">
                  <XCircle size={14} />
                </button>
              )}
              {p.status === 'archived' && (
                <button onClick={() => approve(p.id)} title="Restore" className="p-2 rounded-lg text-gray-400 hover:text-emerald-600 hover:bg-emerald-50 transition-all">
                  <CheckCircle size={14} />
                </button>
              )}
            </>
          )}
        </div>
      </td>
    </tr>
  );

  return (
    <div className="p-6 space-y-5 animate-in">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="page-title">Products</h1>
          <p className="page-subtitle">All products across all suppliers</p>
        </div>
        <div className="flex items-center gap-3">
          {pendingCount > 0 && (
            <div className="flex items-center gap-2 bg-amber-50 border border-amber-200 text-amber-800 text-sm font-semibold px-4 py-2.5 rounded-xl">
              <Clock size={14} /> {pendingCount} pending approval
            </div>
          )}
          <button
            onClick={fetchProducts}
            disabled={loading}
            className="flex items-center gap-2 px-3 py-2.5 bg-white border border-gray-200 rounded-xl text-sm font-semibold text-gray-600 hover:bg-gray-50 transition-all disabled:opacity-50"
          >
            <RefreshCw size={14} className={loading ? 'animate-spin' : ''} /> Refresh
          </button>
        </div>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-4 gap-4">
        <div className="card p-4 flex items-center gap-3">
          <div className="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center"><Package size={18} className="text-blue-600" /></div>
          <div><p className="text-2xl font-black tabular-nums">{total}</p><p className="text-xs text-gray-500 font-semibold">Total Products</p></div>
        </div>
        <div className="card p-4 flex items-center gap-3">
          <div className="w-10 h-10 bg-emerald-50 rounded-xl flex items-center justify-center"><CheckCircle size={18} className="text-emerald-600" /></div>
          <div><p className="text-2xl font-black tabular-nums">{activeCount}</p><p className="text-xs text-gray-500 font-semibold">Active</p></div>
        </div>
        <div className="card p-4 flex items-center gap-3">
          <div className="w-10 h-10 bg-amber-50 rounded-xl flex items-center justify-center"><Clock size={18} className="text-amber-600" /></div>
          <div><p className="text-2xl font-black tabular-nums">{pendingCount}</p><p className="text-xs text-gray-500 font-semibold">Pending Approval</p></div>
        </div>
        <div className="card p-4 flex items-center gap-3">
          <div className="w-10 h-10 bg-purple-50 rounded-xl flex items-center justify-center"><Users size={18} className="text-purple-600" /></div>
          <div><p className="text-2xl font-black tabular-nums">{supplierGroups.length}</p><p className="text-xs text-gray-500 font-semibold">Suppliers</p></div>
        </div>
      </div>

      {/* Filters */}
      <div className="flex items-center gap-3 flex-wrap">
        <div className="relative flex-1 min-w-[220px] max-w-sm">
          <Search size={14} className="absolute left-3.5 top-3 text-gray-400" />
          <input value={search} onChange={(e) => setSearch(e.target.value)} className="input pl-10" placeholder="Search product, supplier, SKU..." />
        </div>
        <div className="flex items-center gap-0.5 bg-white border border-gray-200 rounded-xl p-1">
          {statusFilters.map(({ value, label }) => (
            <button key={value} onClick={() => setStatusFilter(value)}
              className={clsx('px-3 py-1.5 rounded-lg text-xs font-semibold transition-all',
                statusFilter === value ? 'bg-slate-800 text-white shadow-sm' : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50'
              )}>
              {label}
            </button>
          ))}
        </div>

        {/* View Mode Toggle */}
        <div className="flex items-center gap-0.5 bg-white border border-gray-200 rounded-xl p-1">
          <button
            onClick={() => setViewMode('grouped')}
            className={clsx('flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition-all',
              viewMode === 'grouped' ? 'bg-slate-800 text-white shadow-sm' : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50'
            )}
          >
            <Layers size={12} /> By Supplier
          </button>
          <button
            onClick={() => setViewMode('flat')}
            className={clsx('flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition-all',
              viewMode === 'flat' ? 'bg-slate-800 text-white shadow-sm' : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50'
            )}
          >
            <Package size={12} /> All Products
          </button>
        </div>
      </div>

      {/* ─── GROUPED VIEW ─── */}
      {viewMode === 'grouped' && (
        <div className="space-y-4">
          {/* Expand/Collapse controls */}
          {supplierGroups.length > 1 && (
            <div className="flex items-center gap-2">
              <button onClick={expandAll} className="text-xs text-blue-600 hover:text-blue-800 font-semibold">Expand All</button>
              <span className="text-gray-300">•</span>
              <button onClick={collapseAll} className="text-xs text-blue-600 hover:text-blue-800 font-semibold">Collapse All</button>
            </div>
          )}

          {loading ? (
            <div className="card flex items-center justify-center py-16">
              <Loader2 size={24} className="animate-spin text-gray-400" />
              <span className="ml-3 text-sm text-gray-500">Loading products...</span>
            </div>
          ) : supplierGroups.length === 0 ? (
            <div className="card flex flex-col items-center justify-center py-16 text-gray-400">
              <Package size={40} className="mb-3 opacity-50" />
              <p className="text-sm font-semibold">No products found</p>
              <p className="text-xs mt-1">Try adjusting your search or filters</p>
            </div>
          ) : (
            supplierGroups.map((group) => {
              const isExpanded = expandedSuppliers.has(group.supplierId);
              return (
                <div key={group.supplierId} className="card overflow-hidden">
                  {/* Supplier Header */}
                  <button
                    onClick={() => toggleExpanded(group.supplierId)}
                    className="w-full flex items-center justify-between px-5 py-4 hover:bg-gray-50/50 transition-colors"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 rounded-xl bg-slate-100 flex items-center justify-center font-bold text-slate-600 text-sm flex-shrink-0">
                        {group.supplierName.charAt(0)}
                      </div>
                      <div className="text-left">
                        <p className="font-bold text-gray-900 text-sm">{group.supplierName}</p>
                        <p className="text-xs text-gray-400">{group.products.length} product{group.products.length !== 1 ? 's' : ''}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-4">
                      {group.activeCount > 0 && (
                        <span className="text-xs font-bold text-emerald-700 bg-emerald-50 border border-emerald-200 px-2.5 py-1 rounded-full">
                          {group.activeCount} active
                        </span>
                      )}
                      {group.pendingCount > 0 && (
                        <span className="text-xs font-bold text-amber-700 bg-amber-50 border border-amber-200 px-2.5 py-1 rounded-full">
                          {group.pendingCount} pending
                        </span>
                      )}
                      {isExpanded ? <ChevronDown size={16} className="text-gray-400" /> : <ChevronRight size={16} className="text-gray-400" />}
                    </div>
                  </button>

                  {/* Products Table */}
                  {isExpanded && (
                    <div className="border-t border-gray-100">
                      <table className="w-full text-sm">
                        <thead>
                          <tr className="border-b border-gray-100 bg-gray-50/60">
                            <th className="table-header">Product</th>
                            <th className="table-header">Category</th>
                            <th className="table-header text-right">Price</th>
                            <th className="table-header text-right">Stock</th>
                            <th className="table-header text-center">Status</th>
                            <th className="table-header text-center">Available</th>
                            <th className="table-header">Added</th>
                            <th className="table-header text-center">Actions</th>
                          </tr>
                        </thead>
                        <tbody>
                          {group.products.map(renderProductRow)}
                        </tbody>
                      </table>
                    </div>
                  )}
                </div>
              );
            })
          )}
        </div>
      )}

      {/* ─── FLAT VIEW ─── */}
      {viewMode === 'flat' && (
        <div className="card overflow-hidden">
          {loading ? (
            <div className="flex items-center justify-center py-16">
              <Loader2 size={24} className="animate-spin text-gray-400" />
              <span className="ml-3 text-sm text-gray-500">Loading products...</span>
            </div>
          ) : products.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-16 text-gray-400">
              <Package size={40} className="mb-3 opacity-50" />
              <p className="text-sm font-semibold">No products found</p>
              <p className="text-xs mt-1">Try adjusting your search or filters</p>
            </div>
          ) : (
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100 bg-gray-50/60">
                  <th className="table-header">Product</th>
                  <th className="table-header">Supplier</th>
                  <th className="table-header">Category</th>
                  <th className="table-header text-right">Price</th>
                  <th className="table-header text-right">Stock</th>
                  <th className="table-header text-center">Status</th>
                  <th className="table-header text-center">Available</th>
                  <th className="table-header">Added</th>
                  <th className="table-header text-center">Actions</th>
                </tr>
              </thead>
              <tbody>
                {products.map(renderProductRow)}
              </tbody>
            </table>
          )}

          {/* Pagination */}
          {!loading && total > pageSize && (
            <div className="flex items-center justify-between px-4 py-3 border-t border-gray-100">
              <p className="text-xs text-gray-500">
                Showing {(page - 1) * pageSize + 1}–{Math.min(page * pageSize, total)} of {total} products
              </p>
              <div className="flex items-center gap-1">
                <button
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  disabled={page === 1}
                  className="px-3 py-1.5 text-xs font-semibold rounded-lg border border-gray-200 disabled:opacity-40 hover:bg-gray-50 transition-all"
                >
                  Previous
                </button>
                <button
                  onClick={() => setPage((p) => p + 1)}
                  disabled={page * pageSize >= total}
                  className="px-3 py-1.5 text-xs font-semibold rounded-lg border border-gray-200 disabled:opacity-40 hover:bg-gray-50 transition-all"
                >
                  Next
                </button>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
