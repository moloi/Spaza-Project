import { useState, useEffect, useCallback } from 'react';
import {
  Search, CheckCircle, Clock, Eye, ShieldCheck, Users, Store,
  X, Phone, Mail, MapPin, FileText, Calendar, Ban,
} from 'lucide-react';
import { format } from 'date-fns';
import clsx from 'clsx';
import toast from 'react-hot-toast';
import { adminSuppliersApi, adminSpazaOwnersApi } from '../../services/api';
import { TierBadge, Spinner } from '../../components/ui';

type MainTab = 'suppliers' | 'spaza-owners';
type FilterStatus = 'all' | 'verified' | 'pending';

interface SupplierDoc {
  docType: string;
  label: string;
  status: 'pending' | 'approved' | 'rejected';
  uploadedAt: string;
  expiryDate?: string;
}

interface Supplier {
  id: string;
  companyName: string;
  contactName: string;
  email: string;
  phone: string;
  tier: string;
  isVerified: boolean;
  joinedAt: string;
  totalOrders: number;
  totalRevenue: number;
  documents: SupplierDoc[];
}

interface SpazaOwner {
  id: string;
  shopName: string;
  ownerName: string;
  email: string;
  phone: string;
  location: string;
  isVerified: boolean;
  joinedAt: string;
  totalOrders: number;
  totalSpent: number;
  documents: SupplierDoc[];
}

export default function AdminSuppliersPage() {
  const [mainTab, setMainTab] = useState<MainTab>('suppliers');
  const [loading, setLoading] = useState(true);

  // Supplier state
  const [suppliers, setSuppliers] = useState<Supplier[]>([]);
  const [supplierSearch, setSupplierSearch] = useState('');
  const [supplierFilter, setSupplierFilter] = useState<FilterStatus>('all');
  const [selectedSupplier, setSelectedSupplier] = useState<Supplier | null>(null);

  // Spaza Owner state
  const [spazaOwners, setSpazaOwners] = useState<SpazaOwner[]>([]);
  const [spazaSearch, setSpazaSearch] = useState('');
  const [spazaFilter, setSpazaFilter] = useState<FilterStatus>('all');
  const [selectedSpaza, setSelectedSpaza] = useState<SpazaOwner | null>(null);

  // Suspend modal state
  const [suspendTarget, setSuspendTarget] = useState<{ id: string; type: 'supplier' | 'spaza' } | null>(null);
  const [suspendReason, setSuspendReason] = useState('');

  // ─── Data Fetching ────────────────────────────────────────────────────────────
  const fetchSuppliers = useCallback(async () => {
    try {
      setLoading(true);
      const params: Record<string, string> = {};
      if (supplierSearch) params.search = supplierSearch;
      if (supplierFilter !== 'all') params.status = supplierFilter;
      const res = await adminSuppliersApi.list(params);
      const data = res?.data ?? res;
      setSuppliers(Array.isArray(data) ? data : data?.items ?? data?.suppliers ?? []);
    } catch {
      toast.error('Failed to load suppliers');
    } finally {
      setLoading(false);
    }
  }, [supplierSearch, supplierFilter]);

  const fetchSpazaOwners = useCallback(async () => {
    try {
      setLoading(true);
      const params: Record<string, string> = {};
      if (spazaSearch) params.search = spazaSearch;
      if (spazaFilter !== 'all') params.status = spazaFilter;
      const res = await adminSpazaOwnersApi.list(params);
      const data = res?.data ?? res;
      setSpazaOwners(Array.isArray(data) ? data : data?.items ?? data?.owners ?? []);
    } catch {
      toast.error('Failed to load spaza owners');
    } finally {
      setLoading(false);
    }
  }, [spazaSearch, spazaFilter]);

  useEffect(() => {
    if (mainTab === 'suppliers') fetchSuppliers();
    else fetchSpazaOwners();
  }, [mainTab, fetchSuppliers, fetchSpazaOwners]);

  // ─── Actions ──────────────────────────────────────────────────────────────────
  const verifySupplier = async (id: string) => {
    try {
      await adminSuppliersApi.verify(id);
      toast.success('Supplier verified successfully');
      setSelectedSupplier(null);
      fetchSuppliers();
    } catch {
      toast.error('Failed to verify supplier');
    }
  };

  const verifySpazaOwner = async (id: string) => {
    try {
      await adminSpazaOwnersApi.verify(id);
      toast.success('Spaza owner verified successfully');
      setSelectedSpaza(null);
      fetchSpazaOwners();
    } catch {
      toast.error('Failed to verify spaza owner');
    }
  };

  const handleSuspend = async () => {
    if (!suspendTarget) return;
    try {
      if (suspendTarget.type === 'supplier') {
        await adminSuppliersApi.suspend(suspendTarget.id, suspendReason);
        toast.success('Supplier suspended');
        setSelectedSupplier(null);
        fetchSuppliers();
      } else {
        await adminSpazaOwnersApi.suspend(suspendTarget.id, suspendReason);
        toast.success('Spaza owner suspended');
        setSelectedSpaza(null);
        fetchSpazaOwners();
      }
    } catch {
      toast.error('Failed to suspend account');
    } finally {
      setSuspendTarget(null);
      setSuspendReason('');
    }
  };

  // ─── Filtering ────────────────────────────────────────────────────────────────
  const filteredSuppliers = suppliers.filter((s) => {
    const matchSearch = !supplierSearch ||
      s.companyName.toLowerCase().includes(supplierSearch.toLowerCase()) ||
      s.email.toLowerCase().includes(supplierSearch.toLowerCase());
    const matchFilter = supplierFilter === 'all' ||
      (supplierFilter === 'verified' ? s.isVerified : !s.isVerified);
    return matchSearch && matchFilter;
  });

  const filteredSpazaOwners = spazaOwners.filter((o) => {
    const matchSearch = !spazaSearch ||
      o.shopName.toLowerCase().includes(spazaSearch.toLowerCase()) ||
      o.ownerName.toLowerCase().includes(spazaSearch.toLowerCase()) ||
      o.email.toLowerCase().includes(spazaSearch.toLowerCase());
    const matchFilter = spazaFilter === 'all' ||
      (spazaFilter === 'verified' ? o.isVerified : !o.isVerified);
    return matchSearch && matchFilter;
  });

  const totalSupplierVerified = suppliers.filter((s) => s.isVerified).length;
  const totalSupplierPending = suppliers.filter((s) => !s.isVerified).length;
  const totalSpazaVerified = spazaOwners.filter((o) => o.isVerified).length;
  const totalSpazaPending = spazaOwners.filter((o) => !o.isVerified).length;

  if (loading && suppliers.length === 0 && spazaOwners.length === 0) {
    return <div className="flex items-center justify-center h-64"><Spinner /></div>;
  }

  return (
    <div className="p-6 space-y-5 animate-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="page-title">Suppliers &amp; Spaza Owners</h1>
          <p className="page-subtitle">Manage suppliers and spaza shop owners on the platform</p>
        </div>
      </div>

      {/* Main Tabs */}
      <div className="flex items-center gap-1 bg-white border border-gray-200 rounded-xl p-1 w-fit">
        <button
          onClick={() => setMainTab('suppliers')}
          className={clsx(
            'flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold transition-all',
            mainTab === 'suppliers'
              ? 'bg-slate-800 text-white shadow-sm'
              : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50'
          )}
        >
          <Users size={16} />
          Suppliers
        </button>
        <button
          onClick={() => setMainTab('spaza-owners')}
          className={clsx(
            'flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold transition-all',
            mainTab === 'spaza-owners'
              ? 'bg-slate-800 text-white shadow-sm'
              : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50'
          )}
        >
          <Store size={16} />
          Spaza Owners
        </button>
      </div>

      {/* ─── SUPPLIERS TAB ─── */}
      {mainTab === 'suppliers' && (
        <>
          {/* Summary */}
          <div className="grid grid-cols-3 gap-4">
            <div className="card p-4 flex items-center gap-3">
              <div className="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center"><Users size={18} className="text-blue-600" /></div>
              <div><p className="text-2xl font-black text-gray-900 tabular-nums">{suppliers.length}</p><p className="text-xs text-gray-500 font-semibold">Total Suppliers</p></div>
            </div>
            <div className="card p-4 flex items-center gap-3">
              <div className="w-10 h-10 bg-emerald-50 rounded-xl flex items-center justify-center"><CheckCircle size={18} className="text-emerald-600" /></div>
              <div><p className="text-2xl font-black text-gray-900 tabular-nums">{totalSupplierVerified}</p><p className="text-xs text-gray-500 font-semibold">Verified</p></div>
            </div>
            <div className="card p-4 flex items-center gap-3">
              <div className="w-10 h-10 bg-amber-50 rounded-xl flex items-center justify-center"><Clock size={18} className="text-amber-600" /></div>
              <div><p className="text-2xl font-black text-gray-900 tabular-nums">{totalSupplierPending}</p><p className="text-xs text-gray-500 font-semibold">Pending Verification</p></div>
            </div>
          </div>

          {/* Filters */}
          <div className="flex items-center gap-3">
            <div className="relative flex-1 max-w-sm">
              <Search size={14} className="absolute left-3.5 top-3 text-gray-400" />
              <input value={supplierSearch} onChange={(e) => setSupplierSearch(e.target.value)} className="input pl-10" placeholder="Search by name or email..." />
            </div>
            <div className="flex items-center gap-0.5 bg-white border border-gray-200 rounded-xl p-1">
              {(['all', 'verified', 'pending'] as FilterStatus[]).map((f) => (
                <button
                  key={f}
                  onClick={() => setSupplierFilter(f)}
                  className={clsx('px-3 py-1.5 rounded-lg text-xs font-semibold capitalize transition-all',
                    supplierFilter === f ? 'bg-slate-800 text-white shadow-sm' : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50'
                  )}
                >
                  {f}
                </button>
              ))}
            </div>
          </div>

          {/* Table */}
          <div className="card overflow-hidden">
            {filteredSuppliers.length === 0 ? (
              <div className="p-16 text-center">
                <Users size={36} className="text-gray-200 mx-auto mb-3" />
                <p className="font-bold text-gray-600">No suppliers found</p>
                <p className="text-sm text-gray-400 mt-1">Try adjusting your filters</p>
              </div>
            ) : (
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-100 bg-gray-50/60">
                    <th className="table-header">Supplier</th>
                    <th className="table-header">Tier</th>
                    <th className="table-header text-right">Orders</th>
                    <th className="table-header text-right">Revenue</th>
                    <th className="table-header text-center">Documents</th>
                    <th className="table-header text-center">Status</th>
                    <th className="table-header">Joined</th>
                    <th className="table-header text-center">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredSuppliers.map((s) => {
                    const pendingDocs = (s.documents ?? []).filter((d) => d.status === 'pending').length;
                    const approvedDocs = (s.documents ?? []).filter((d) => d.status === 'approved').length;
                    return (
                      <tr key={s.id} className="table-row">
                        <td className="table-cell">
                          <div className="flex items-center gap-3">
                            <div className="w-9 h-9 rounded-xl bg-slate-100 flex items-center justify-center font-bold text-slate-600 text-sm flex-shrink-0">
                              {s.companyName.charAt(0)}
                            </div>
                            <div>
                              <p className="font-semibold text-gray-900">{s.companyName}</p>
                              <p className="text-xs text-gray-400">{s.email}</p>
                            </div>
                          </div>
                        </td>
                        <td className="table-cell"><TierBadge tier={s.tier} /></td>
                        <td className="table-cell text-right font-bold tabular-nums">{s.totalOrders}</td>
                        <td className="table-cell text-right font-bold text-emerald-700 tabular-nums">R{(s.totalRevenue ?? 0).toLocaleString()}</td>
                        <td className="table-cell text-center">
                          <div className="flex items-center justify-center gap-1.5">
                            <span className="text-xs font-bold text-emerald-700 bg-emerald-50 border border-emerald-200 px-2 py-0.5 rounded-full">{approvedDocs} ✓</span>
                            {pendingDocs > 0 && (
                              <span className="text-xs font-bold text-amber-700 bg-amber-50 border border-amber-200 px-2 py-0.5 rounded-full">{pendingDocs} pending</span>
                            )}
                          </div>
                        </td>
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
                        <td className="table-cell">
                          <div className="flex items-center justify-center gap-1">
                            <button
                              onClick={() => setSelectedSupplier(s)}
                              className="p-2 rounded-lg text-gray-400 hover:text-blue-600 hover:bg-blue-50 transition-all"
                              title="View Details"
                            >
                              <Eye size={14} />
                            </button>
                            {!s.isVerified && (
                              <button
                                onClick={() => verifySupplier(s.id)}
                                className="p-2 rounded-lg text-gray-400 hover:text-emerald-600 hover:bg-emerald-50 transition-all"
                                title="Verify Supplier"
                              >
                                <ShieldCheck size={14} />
                              </button>
                            )}
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            )}
          </div>
        </>
      )}

      {/* ─── SPAZA OWNERS TAB ─── */}
      {mainTab === 'spaza-owners' && (
        <>
          {/* Summary */}
          <div className="grid grid-cols-3 gap-4">
            <div className="card p-4 flex items-center gap-3">
              <div className="w-10 h-10 bg-purple-50 rounded-xl flex items-center justify-center"><Store size={18} className="text-purple-600" /></div>
              <div><p className="text-2xl font-black text-gray-900 tabular-nums">{spazaOwners.length}</p><p className="text-xs text-gray-500 font-semibold">Total Spaza Owners</p></div>
            </div>
            <div className="card p-4 flex items-center gap-3">
              <div className="w-10 h-10 bg-emerald-50 rounded-xl flex items-center justify-center"><CheckCircle size={18} className="text-emerald-600" /></div>
              <div><p className="text-2xl font-black text-gray-900 tabular-nums">{totalSpazaVerified}</p><p className="text-xs text-gray-500 font-semibold">Verified</p></div>
            </div>
            <div className="card p-4 flex items-center gap-3">
              <div className="w-10 h-10 bg-amber-50 rounded-xl flex items-center justify-center"><Clock size={18} className="text-amber-600" /></div>
              <div><p className="text-2xl font-black text-gray-900 tabular-nums">{totalSpazaPending}</p><p className="text-xs text-gray-500 font-semibold">Pending Verification</p></div>
            </div>
          </div>

          {/* Filters */}
          <div className="flex items-center gap-3">
            <div className="relative flex-1 max-w-sm">
              <Search size={14} className="absolute left-3.5 top-3 text-gray-400" />
              <input value={spazaSearch} onChange={(e) => setSpazaSearch(e.target.value)} className="input pl-10" placeholder="Search by shop name, owner or email..." />
            </div>
            <div className="flex items-center gap-0.5 bg-white border border-gray-200 rounded-xl p-1">
              {(['all', 'verified', 'pending'] as FilterStatus[]).map((f) => (
                <button
                  key={f}
                  onClick={() => setSpazaFilter(f)}
                  className={clsx('px-3 py-1.5 rounded-lg text-xs font-semibold capitalize transition-all',
                    spazaFilter === f ? 'bg-slate-800 text-white shadow-sm' : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50'
                  )}
                >
                  {f}
                </button>
              ))}
            </div>
          </div>

          {/* Table */}
          <div className="card overflow-hidden">
            {filteredSpazaOwners.length === 0 ? (
              <div className="p-16 text-center">
                <Store size={36} className="text-gray-200 mx-auto mb-3" />
                <p className="font-bold text-gray-600">No spaza owners found</p>
                <p className="text-sm text-gray-400 mt-1">Try adjusting your filters</p>
              </div>
            ) : (
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-100 bg-gray-50/60">
                    <th className="table-header">Shop</th>
                    <th className="table-header">Owner</th>
                    <th className="table-header">Location</th>
                    <th className="table-header text-right">Orders</th>
                    <th className="table-header text-right">Total Spent</th>
                    <th className="table-header text-center">Documents</th>
                    <th className="table-header text-center">Status</th>
                    <th className="table-header">Joined</th>
                    <th className="table-header text-center">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredSpazaOwners.map((o) => {
                    const pendingDocs = (o.documents ?? []).filter((d) => d.status === 'pending').length;
                    const approvedDocs = (o.documents ?? []).filter((d) => d.status === 'approved').length;
                    return (
                      <tr key={o.id} className="table-row">
                        <td className="table-cell">
                          <div className="flex items-center gap-3">
                            <div className="w-9 h-9 rounded-xl bg-purple-50 flex items-center justify-center font-bold text-purple-600 text-sm flex-shrink-0">
                              {o.shopName.charAt(0)}
                            </div>
                            <div>
                              <p className="font-semibold text-gray-900">{o.shopName}</p>
                              <p className="text-xs text-gray-400">{o.email}</p>
                            </div>
                          </div>
                        </td>
                        <td className="table-cell font-medium text-gray-700">{o.ownerName}</td>
                        <td className="table-cell text-xs text-gray-500">{o.location}</td>
                        <td className="table-cell text-right font-bold tabular-nums">{o.totalOrders}</td>
                        <td className="table-cell text-right font-bold text-emerald-700 tabular-nums">R{(o.totalSpent ?? 0).toLocaleString()}</td>
                        <td className="table-cell text-center">
                          <div className="flex items-center justify-center gap-1.5">
                            <span className="text-xs font-bold text-emerald-700 bg-emerald-50 border border-emerald-200 px-2 py-0.5 rounded-full">{approvedDocs} ✓</span>
                            {pendingDocs > 0 && (
                              <span className="text-xs font-bold text-amber-700 bg-amber-50 border border-amber-200 px-2 py-0.5 rounded-full">{pendingDocs} pending</span>
                            )}
                          </div>
                        </td>
                        <td className="table-cell text-center">
                          {o.isVerified ? (
                            <span className="inline-flex items-center gap-1 text-xs font-bold text-emerald-700 bg-emerald-50 border border-emerald-200 px-2.5 py-1 rounded-full">
                              <CheckCircle size={11} /> Verified
                            </span>
                          ) : (
                            <span className="inline-flex items-center gap-1 text-xs font-bold text-amber-700 bg-amber-50 border border-amber-200 px-2.5 py-1 rounded-full">
                              <Clock size={11} /> Pending
                            </span>
                          )}
                        </td>
                        <td className="table-cell text-xs text-gray-400">{format(new Date(o.joinedAt), 'dd MMM yyyy')}</td>
                        <td className="table-cell">
                          <div className="flex items-center justify-center gap-1">
                            <button
                              onClick={() => setSelectedSpaza(o)}
                              className="p-2 rounded-lg text-gray-400 hover:text-blue-600 hover:bg-blue-50 transition-all"
                              title="View Details"
                            >
                              <Eye size={14} />
                            </button>
                            {!o.isVerified && (
                              <button
                                onClick={() => verifySpazaOwner(o.id)}
                                className="p-2 rounded-lg text-gray-400 hover:text-emerald-600 hover:bg-emerald-50 transition-all"
                                title="Verify Spaza Owner"
                              >
                                <ShieldCheck size={14} />
                              </button>
                            )}
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            )}
          </div>
        </>
      )}

      {/* ─── SUPPLIER DETAIL MODAL ─── */}
      {selectedSupplier && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={() => setSelectedSupplier(null)} />
          <div className="relative bg-white rounded-2xl shadow-card-xl w-full max-w-2xl max-h-[90vh] flex flex-col animate-scale-in">
            {/* Header */}
            <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100 flex-shrink-0">
              <div className="flex items-center gap-3">
                <div className="w-11 h-11 rounded-xl bg-slate-100 flex items-center justify-center font-bold text-slate-700 text-lg">
                  {selectedSupplier.companyName.charAt(0)}
                </div>
                <div>
                  <p className="font-bold text-gray-900">{selectedSupplier.companyName}</p>
                  <p className="text-xs text-gray-400">{selectedSupplier.contactName}</p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                {selectedSupplier.isVerified ? (
                  <span className="inline-flex items-center gap-1 text-xs font-bold text-emerald-700 bg-emerald-50 border border-emerald-200 px-2.5 py-1 rounded-full">
                    <CheckCircle size={11} /> Verified
                  </span>
                ) : (
                  <span className="inline-flex items-center gap-1 text-xs font-bold text-amber-700 bg-amber-50 border border-amber-200 px-2.5 py-1 rounded-full">
                    <Clock size={11} /> Pending
                  </span>
                )}
                <button onClick={() => setSelectedSupplier(null)} className="p-2 rounded-lg text-gray-400 hover:text-gray-700 hover:bg-gray-100 transition-all">
                  <X size={15} />
                </button>
              </div>
            </div>

            {/* Body */}
            <div className="flex-1 overflow-y-auto p-6 space-y-6">
              {/* Contact Info */}
              <div className="grid grid-cols-2 gap-4">
                <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                  <Mail size={15} className="text-gray-400" />
                  <div>
                    <p className="text-[11px] text-gray-400 font-semibold uppercase">Email</p>
                    <p className="text-sm font-medium text-gray-900">{selectedSupplier.email}</p>
                  </div>
                </div>
                <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                  <Phone size={15} className="text-gray-400" />
                  <div>
                    <p className="text-[11px] text-gray-400 font-semibold uppercase">Phone</p>
                    <p className="text-sm font-medium text-gray-900">{selectedSupplier.phone}</p>
                  </div>
                </div>
                <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                  <Calendar size={15} className="text-gray-400" />
                  <div>
                    <p className="text-[11px] text-gray-400 font-semibold uppercase">Joined</p>
                    <p className="text-sm font-medium text-gray-900">{format(new Date(selectedSupplier.joinedAt), 'dd MMM yyyy')}</p>
                  </div>
                </div>
                <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                  <Users size={15} className="text-gray-400" />
                  <div>
                    <p className="text-[11px] text-gray-400 font-semibold uppercase">Tier</p>
                    <TierBadge tier={selectedSupplier.tier} />
                  </div>
                </div>
              </div>

              {/* Stats */}
              <div className="grid grid-cols-2 gap-4">
                <div className="card p-4 text-center">
                  <p className="text-2xl font-black text-gray-900 tabular-nums">{selectedSupplier.totalOrders}</p>
                  <p className="text-xs text-gray-500 font-semibold mt-1">Total Orders</p>
                </div>
                <div className="card p-4 text-center">
                  <p className="text-2xl font-black text-emerald-700 tabular-nums">R{(selectedSupplier.totalRevenue ?? 0).toLocaleString()}</p>
                  <p className="text-xs text-gray-500 font-semibold mt-1">Total Revenue</p>
                </div>
              </div>

              {/* Documents */}
              {selectedSupplier.documents && selectedSupplier.documents.length > 0 && (
                <div>
                  <h3 className="text-sm font-bold text-gray-900 mb-3 flex items-center gap-2">
                    <FileText size={14} className="text-gray-400" /> Documents
                  </h3>
                  <div className="space-y-2">
                    {selectedSupplier.documents.map((doc, i) => (
                      <div key={i} className="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 bg-white rounded-lg flex items-center justify-center border border-gray-200">
                            <FileText size={13} className="text-gray-400" />
                          </div>
                          <div>
                            <p className="text-sm font-semibold text-gray-900">{doc.label || doc.docType}</p>
                            <p className="text-xs text-gray-400">Uploaded {format(new Date(doc.uploadedAt), 'dd MMM yyyy')}</p>
                          </div>
                        </div>
                        <span className={clsx('text-xs font-bold px-2.5 py-1 rounded-full border capitalize',
                          doc.status === 'approved' && 'bg-emerald-50 text-emerald-700 border-emerald-200',
                          doc.status === 'pending' && 'bg-amber-50 text-amber-700 border-amber-200',
                          doc.status === 'rejected' && 'bg-red-50 text-red-700 border-red-200',
                        )}>
                          {doc.status}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* Footer Actions */}
            <div className="flex items-center justify-end gap-3 px-6 py-4 border-t border-gray-100 flex-shrink-0">
              {selectedSupplier.isVerified && (
                <button
                  onClick={() => setSuspendTarget({ id: selectedSupplier.id, type: 'supplier' })}
                  className="flex items-center gap-1.5 text-sm font-semibold bg-red-500 text-white px-5 py-2.5 rounded-xl hover:bg-red-600 transition-colors"
                >
                  <Ban size={14} /> Suspend
                </button>
              )}
              {!selectedSupplier.isVerified && (
                <button
                  onClick={() => verifySupplier(selectedSupplier.id)}
                  className="flex items-center gap-1.5 text-sm font-semibold bg-emerald-600 text-white px-5 py-2.5 rounded-xl hover:bg-emerald-700 transition-colors"
                >
                  <ShieldCheck size={14} /> Verify Supplier
                </button>
              )}
            </div>
          </div>
        </div>
      )}

      {/* ─── SPAZA OWNER DETAIL MODAL ─── */}
      {selectedSpaza && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={() => setSelectedSpaza(null)} />
          <div className="relative bg-white rounded-2xl shadow-card-xl w-full max-w-2xl max-h-[90vh] flex flex-col animate-scale-in">
            {/* Header */}
            <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100 flex-shrink-0">
              <div className="flex items-center gap-3">
                <div className="w-11 h-11 rounded-xl bg-purple-50 flex items-center justify-center font-bold text-purple-700 text-lg">
                  {selectedSpaza.shopName.charAt(0)}
                </div>
                <div>
                  <p className="font-bold text-gray-900">{selectedSpaza.shopName}</p>
                  <p className="text-xs text-gray-400">{selectedSpaza.ownerName}</p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                {selectedSpaza.isVerified ? (
                  <span className="inline-flex items-center gap-1 text-xs font-bold text-emerald-700 bg-emerald-50 border border-emerald-200 px-2.5 py-1 rounded-full">
                    <CheckCircle size={11} /> Verified
                  </span>
                ) : (
                  <span className="inline-flex items-center gap-1 text-xs font-bold text-amber-700 bg-amber-50 border border-amber-200 px-2.5 py-1 rounded-full">
                    <Clock size={11} /> Pending
                  </span>
                )}
                <button onClick={() => setSelectedSpaza(null)} className="p-2 rounded-lg text-gray-400 hover:text-gray-700 hover:bg-gray-100 transition-all">
                  <X size={15} />
                </button>
              </div>
            </div>

            {/* Body */}
            <div className="flex-1 overflow-y-auto p-6 space-y-6">
              {/* Contact Info */}
              <div className="grid grid-cols-2 gap-4">
                <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                  <Mail size={15} className="text-gray-400" />
                  <div>
                    <p className="text-[11px] text-gray-400 font-semibold uppercase">Email</p>
                    <p className="text-sm font-medium text-gray-900">{selectedSpaza.email}</p>
                  </div>
                </div>
                <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                  <Phone size={15} className="text-gray-400" />
                  <div>
                    <p className="text-[11px] text-gray-400 font-semibold uppercase">Phone</p>
                    <p className="text-sm font-medium text-gray-900">{selectedSpaza.phone}</p>
                  </div>
                </div>
                <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                  <MapPin size={15} className="text-gray-400" />
                  <div>
                    <p className="text-[11px] text-gray-400 font-semibold uppercase">Location</p>
                    <p className="text-sm font-medium text-gray-900">{selectedSpaza.location}</p>
                  </div>
                </div>
                <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                  <Calendar size={15} className="text-gray-400" />
                  <div>
                    <p className="text-[11px] text-gray-400 font-semibold uppercase">Joined</p>
                    <p className="text-sm font-medium text-gray-900">{format(new Date(selectedSpaza.joinedAt), 'dd MMM yyyy')}</p>
                  </div>
                </div>
              </div>

              {/* Stats */}
              <div className="grid grid-cols-2 gap-4">
                <div className="card p-4 text-center">
                  <p className="text-2xl font-black text-gray-900 tabular-nums">{selectedSpaza.totalOrders}</p>
                  <p className="text-xs text-gray-500 font-semibold mt-1">Total Orders</p>
                </div>
                <div className="card p-4 text-center">
                  <p className="text-2xl font-black text-emerald-700 tabular-nums">R{(selectedSpaza.totalSpent ?? 0).toLocaleString()}</p>
                  <p className="text-xs text-gray-500 font-semibold mt-1">Total Spent</p>
                </div>
              </div>

              {/* Documents */}
              {selectedSpaza.documents && selectedSpaza.documents.length > 0 && (
                <div>
                  <h3 className="text-sm font-bold text-gray-900 mb-3 flex items-center gap-2">
                    <FileText size={14} className="text-gray-400" /> Documents
                  </h3>
                  <div className="space-y-2">
                    {selectedSpaza.documents.map((doc, i) => (
                      <div key={i} className="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 bg-white rounded-lg flex items-center justify-center border border-gray-200">
                            <FileText size={13} className="text-gray-400" />
                          </div>
                          <div>
                            <p className="text-sm font-semibold text-gray-900">{doc.label || doc.docType}</p>
                            <p className="text-xs text-gray-400">Uploaded {format(new Date(doc.uploadedAt), 'dd MMM yyyy')}</p>
                          </div>
                        </div>
                        <span className={clsx('text-xs font-bold px-2.5 py-1 rounded-full border capitalize',
                          doc.status === 'approved' && 'bg-emerald-50 text-emerald-700 border-emerald-200',
                          doc.status === 'pending' && 'bg-amber-50 text-amber-700 border-amber-200',
                          doc.status === 'rejected' && 'bg-red-50 text-red-700 border-red-200',
                        )}>
                          {doc.status}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* Footer Actions */}
            <div className="flex items-center justify-end gap-3 px-6 py-4 border-t border-gray-100 flex-shrink-0">
              {selectedSpaza.isVerified && (
                <button
                  onClick={() => setSuspendTarget({ id: selectedSpaza.id, type: 'spaza' })}
                  className="flex items-center gap-1.5 text-sm font-semibold bg-red-500 text-white px-5 py-2.5 rounded-xl hover:bg-red-600 transition-colors"
                >
                  <Ban size={14} /> Suspend
                </button>
              )}
              {!selectedSpaza.isVerified && (
                <button
                  onClick={() => verifySpazaOwner(selectedSpaza.id)}
                  className="flex items-center gap-1.5 text-sm font-semibold bg-emerald-600 text-white px-5 py-2.5 rounded-xl hover:bg-emerald-700 transition-colors"
                >
                  <ShieldCheck size={14} /> Verify Spaza Owner
                </button>
              )}
            </div>
          </div>
        </div>
      )}

      {/* ─── SUSPEND MODAL ─── */}
      {suspendTarget && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={() => setSuspendTarget(null)} />
          <div className="relative bg-white rounded-2xl shadow-card-xl w-full max-w-md animate-scale-in">
            <div className="px-6 py-5 border-b border-gray-100">
              <h2 className="font-bold text-gray-900">Suspend Account</h2>
              <p className="text-sm text-gray-500 mt-0.5">Provide a reason for suspending this account</p>
            </div>
            <div className="p-6 space-y-4">
              <div>
                <label className="label">Reason</label>
                <textarea
                  value={suspendReason}
                  onChange={(e) => setSuspendReason(e.target.value)}
                  className="input resize-none"
                  rows={3}
                  placeholder="e.g. Fraudulent activity, violation of terms..."
                />
              </div>
              <div className="flex gap-3 justify-end">
                <button onClick={() => setSuspendTarget(null)} className="btn-secondary">Cancel</button>
                <button
                  onClick={handleSuspend}
                  disabled={!suspendReason.trim()}
                  className="btn-danger"
                >
                  Suspend Account
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
