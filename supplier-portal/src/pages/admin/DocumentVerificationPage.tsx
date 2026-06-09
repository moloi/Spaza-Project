import { useState, useEffect } from 'react';
import {
  CheckCircle, XCircle, Clock, Eye, FileText, Search,
  AlertTriangle, X, Download, ExternalLink, Store, Truck,
} from 'lucide-react';
import toast from 'react-hot-toast';
import { format } from 'date-fns';
import clsx from 'clsx';
import api, { resolveUploadUrl } from '../../services/api';
import { Spinner } from '../../components/ui';

type DocStatus = 'pending' | 'approved' | 'rejected';
type FilterStatus = 'all' | DocStatus;
type DocTab = 'supplier' | 'spaza';

interface SupplierDoc {
  id: string;
  docType: string;
  label: string;
  docUrl: string;
  status: DocStatus;
  expiryDate?: string;
  rejectionNote?: string;
  uploadedAt: string;
  supplierId: string;
  supplierName: string;
  supplierEmail: string;
}

const docLabels: Record<string, string> = {
  cipc_certificate: 'CIPC Certificate',
  tax_clearance: 'Tax Clearance Certificate',
  bee_certificate: 'BEE Certificate',
  product_license: 'Product License',
};

const statusConfig: Record<DocStatus, { label: string; icon: React.ReactNode; className: string }> = {
  pending:  { label: 'Pending',  icon: <Clock size={13} />,       className: 'bg-amber-50 text-amber-700 border-amber-200' },
  approved: { label: 'Approved', icon: <CheckCircle size={13} />, className: 'bg-emerald-50 text-emerald-700 border-emerald-200' },
  rejected: { label: 'Rejected', icon: <XCircle size={13} />,     className: 'bg-red-50 text-red-700 border-red-200' },
};

export default function DocumentVerificationPage() {
  const [activeTab, setActiveTab]   = useState<DocTab>('supplier');
  const [allDocs, setAllDocs]       = useState<SupplierDoc[]>([]);
  const [loading, setLoading]       = useState(true);
  const [summary, setSummary]       = useState({ pending: 0, approved: 0, rejected: 0 });
  const [search, setSearch]         = useState('');
  const [statusFilter, setStatusFilter] = useState<FilterStatus>('all');
  const [rejectReason, setRejectReason] = useState('');
  const [rejectTarget, setRejectTarget] = useState<string | null>(null);
  const [previewDoc, setPreviewDoc] = useState<SupplierDoc | null>(null);

  const fetchDocs = async (status?: string, q?: string, tab?: DocTab) => {
    try {
      setLoading(true);
      const params: Record<string, string> = {};
      if (status && status !== 'all') params.status = status;
      if (q) params.search = q;
      const currentTab = tab ?? activeTab;
      const endpoint = currentTab === 'spaza' ? '/compliance/documents/shop' : '/compliance/documents';
      const res = await api.get(endpoint, { params });
      const { docs, summary: s } = res.data.data;
      setAllDocs(docs.map((d: any) => ({ ...d, label: docLabels[d.docType] ?? d.docType, uploadedAt: d.createdAt })));
      setSummary(s);
    } catch {
      toast.error('Failed to load documents');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchDocs(); }, []);

  const handleTabChange = (tab: DocTab) => {
    setActiveTab(tab);
    setSearch('');
    setStatusFilter('all');
    fetchDocs(undefined, undefined, tab);
  };

  const filtered = allDocs.filter((d) => {
    const matchSearch = !search ||
      d.supplierName.toLowerCase().includes(search.toLowerCase()) ||
      d.label.toLowerCase().includes(search.toLowerCase());
    const matchStatus = statusFilter === 'all' || d.status === statusFilter;
    return matchSearch && matchStatus;
  });

  const pendingCount  = summary.pending;
  const approvedCount = summary.approved;
  const rejectedCount = summary.rejected;

  const updateDocStatus = async (id: string, status: DocStatus, reason?: string) => {
    try {
      if (status === 'approved') {
        await api.patch(`/compliance/documents/${id}/approve`);
      } else {
        await api.patch(`/compliance/documents/${id}/reject`, { reason });
      }
      toast.success(status === 'approved' ? '✅ Document approved' : '❌ Document rejected');
      setRejectTarget(null);
      setRejectReason('');
      setPreviewDoc(null);
      fetchDocs(statusFilter !== 'all' ? statusFilter : undefined, search || undefined, activeTab);
    } catch {
      toast.error('Failed to update document status');
    }
  };

  if (loading) return <div className="flex items-center justify-center h-64"><Spinner /></div>;

  return (
    <div className="p-6 space-y-5 animate-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="page-title">Document Verification</h1>
          <p className="page-subtitle">Review and verify supplier and spaza owner compliance documents</p>
        </div>
        {pendingCount > 0 && (
          <div className="flex items-center gap-2 bg-amber-50 border border-amber-200 text-amber-800 text-sm font-semibold px-4 py-2.5 rounded-xl">
            <AlertTriangle size={15} />
            {pendingCount} document{pendingCount !== 1 ? 's' : ''} awaiting review
          </div>
        )}
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-3 gap-4">
        {[
          { label: 'Pending Review', count: pendingCount,  color: 'bg-amber-50 border-amber-200',   text: 'text-amber-700',   icon: <Clock size={18} className="text-amber-600" /> },
          { label: 'Approved',       count: approvedCount, color: 'bg-emerald-50 border-emerald-200', text: 'text-emerald-700', icon: <CheckCircle size={18} className="text-emerald-600" /> },
          { label: 'Rejected',       count: rejectedCount, color: 'bg-red-50 border-red-200',        text: 'text-red-700',     icon: <XCircle size={18} className="text-red-500" /> },
        ].map(({ label, count, color, text, icon }) => (
          <div key={label} className={`card p-4 border-2 ${color} flex items-center gap-4`}>
            <div className="w-10 h-10 bg-white rounded-xl flex items-center justify-center shadow-sm flex-shrink-0">{icon}</div>
            <div>
              <p className={`text-2xl font-black tabular-nums ${text}`}>{count}</p>
              <p className="text-xs font-semibold text-gray-500">{label}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Supplier / Spaza Owner Tabs */}
      <div className="flex items-center gap-1 bg-white border border-gray-200 rounded-xl p-1 w-fit">
        <button
          onClick={() => handleTabChange('supplier')}
          className={clsx(
            'flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold transition-all',
            activeTab === 'supplier' ? 'bg-slate-800 text-white shadow-sm' : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50'
          )}
        >
          <Truck size={15} />
          Supplier Documents
        </button>
        <button
          onClick={() => handleTabChange('spaza')}
          className={clsx(
            'flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold transition-all',
            activeTab === 'spaza' ? 'bg-slate-800 text-white shadow-sm' : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50'
          )}
        >
          <Store size={15} />
          Spaza Owner Documents
        </button>
      </div>

      {/* Filters */}
      <div className="flex items-center gap-3 flex-wrap">
        <div className="relative flex-1 min-w-[220px] max-w-sm">
          <Search size={14} className="absolute left-3.5 top-3 text-gray-400" />
          <input value={search} onChange={(e) => setSearch(e.target.value)} className="input pl-10" placeholder={activeTab === 'spaza' ? 'Search shop or document...' : 'Search supplier or document...'} />
        </div>
        <div className="flex items-center gap-0.5 bg-white border border-gray-200 rounded-xl p-1">
          {(['all', 'pending', 'approved', 'rejected'] as FilterStatus[]).map((value) => {
            const count = value === 'all' ? allDocs.length : value === 'pending' ? pendingCount : value === 'approved' ? approvedCount : rejectedCount;
            return (
              <button
                key={value}
                onClick={() => { setStatusFilter(value); fetchDocs(value !== 'all' ? value : undefined, search || undefined, activeTab); }}
                className={clsx(
                  'flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition-all capitalize',
                  statusFilter === value ? 'bg-slate-800 text-white shadow-sm' : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50'
                )}
              >
                {value}
                <span className={clsx('text-[10px] font-black px-1.5 py-0.5 rounded-full min-w-[18px] text-center',
                  statusFilter === value ? 'bg-white/20 text-white' : 'bg-gray-100 text-gray-600'
                )}>{count}</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Documents Table */}
      <div className="card overflow-hidden">
        {filtered.length === 0 ? (
          <div className="p-16 text-center">
            <FileText size={36} className="text-gray-200 mx-auto mb-3" />
            <p className="font-bold text-gray-600">No documents found</p>
            <p className="text-sm text-gray-400 mt-1">Try adjusting your filters</p>
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 bg-gray-50/60">
                <th className="table-header">Document</th>
                <th className="table-header">{activeTab === 'spaza' ? 'Spaza Shop' : 'Supplier'}</th>
                <th className="table-header">Uploaded</th>
                <th className="table-header">Expiry</th>
                <th className="table-header text-center">Status</th>
                <th className="table-header text-center">Actions</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((doc, i) => (
                <tr key={i} className="table-row">
                  <td className="table-cell">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 bg-slate-100 rounded-lg flex items-center justify-center flex-shrink-0">
                        <FileText size={14} className="text-slate-500" />
                      </div>
                      <p className="font-semibold text-gray-900">{doc.label}</p>
                    </div>
                  </td>
                  <td className="table-cell">
                    <p className="font-semibold text-gray-900">{doc.supplierName}</p>
                    <p className="text-xs text-gray-400">{doc.supplierEmail}</p>
                  </td>
                  <td className="table-cell text-xs text-gray-500">
                    {format(new Date(doc.uploadedAt), 'dd MMM yyyy')}
                  </td>
                  <td className="table-cell text-xs text-gray-500">
                    {doc.expiryDate ? format(new Date(doc.expiryDate), 'dd MMM yyyy') : '—'}
                  </td>
                  <td className="table-cell text-center">
                    <span className={clsx('inline-flex items-center gap-1.5 text-xs font-bold px-2.5 py-1 rounded-full border', statusConfig[doc.status].className)}>
                      {statusConfig[doc.status].icon}
                      {statusConfig[doc.status].label}
                    </span>
                  </td>
                  <td className="table-cell">
                    <div className="flex items-center justify-center gap-1.5">
                      {/* View */}
                      <button
                        className="p-2 rounded-lg text-gray-400 hover:text-blue-600 hover:bg-blue-50 transition-all"
                        title="View Document"
                        onClick={() => setPreviewDoc(doc)}
                      >
                        <Eye size={14} />
                      </button>

                      {doc.status !== 'approved' && (
                        <button
                          onClick={() => updateDocStatus(doc.id, 'approved')}
                          className="p-2 rounded-lg text-gray-400 hover:text-emerald-600 hover:bg-emerald-50 transition-all"
                          title="Approve"
                        >
                          <CheckCircle size={14} />
                        </button>
                      )}
                      {doc.status !== 'rejected' && (
                        <button
                          onClick={() => setRejectTarget(doc.id)}
                          className="p-2 rounded-lg text-gray-400 hover:text-red-500 hover:bg-red-50 transition-all"
                          title="Reject"
                        >
                          <XCircle size={14} />
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

      {/* Document Preview Modal */}
      {previewDoc && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={() => setPreviewDoc(null)} />
          <div className="relative bg-white rounded-2xl shadow-card-xl w-full max-w-3xl max-h-[90vh] flex flex-col animate-scale-in">
            {/* Header */}
            <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100 flex-shrink-0">
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 bg-slate-100 rounded-xl flex items-center justify-center">
                  <FileText size={16} className="text-slate-600" />
                </div>
                <div>
                  <p className="font-bold text-gray-900 text-sm">{previewDoc.label}</p>
                  <p className="text-xs text-gray-400">{previewDoc.supplierName}</p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <span className={clsx('inline-flex items-center gap-1.5 text-xs font-bold px-2.5 py-1 rounded-full border', statusConfig[previewDoc.status].className)}>
                  {statusConfig[previewDoc.status].icon}
                  {statusConfig[previewDoc.status].label}
                </span>
                {previewDoc.docUrl && previewDoc.docUrl !== '#' && (
                  <>
                    <a href={resolveUploadUrl(previewDoc.docUrl)} download className="p-2 rounded-lg text-gray-400 hover:text-blue-600 hover:bg-blue-50 transition-all" title="Download">
                      <Download size={15} />
                    </a>
                    <a href={resolveUploadUrl(previewDoc.docUrl)} target="_blank" rel="noreferrer" className="p-2 rounded-lg text-gray-400 hover:text-blue-600 hover:bg-blue-50 transition-all" title="Open in new tab">
                      <ExternalLink size={15} />
                    </a>
                  </>
                )}
                <button onClick={() => setPreviewDoc(null)} className="p-2 rounded-lg text-gray-400 hover:text-gray-700 hover:bg-gray-100 transition-all">
                  <X size={15} />
                </button>
              </div>
            </div>

            {/* Document Info Bar */}
            <div className="flex items-center gap-6 px-6 py-3 bg-gray-50 border-b border-gray-100 text-xs text-gray-500 flex-shrink-0">
              <span><strong className="text-gray-700">Uploaded:</strong> {format(new Date(previewDoc.uploadedAt), 'dd MMM yyyy')}</span>
              {previewDoc.expiryDate && <span><strong className="text-gray-700">Expires:</strong> {format(new Date(previewDoc.expiryDate), 'dd MMM yyyy')}</span>}
              <span><strong className="text-gray-700">Supplier:</strong> {previewDoc.supplierEmail}</span>
            </div>

            {/* Preview Area */}
            <div className="flex-1 overflow-auto p-6 min-h-0">
              {(() => {
                const resolvedUrl = resolveUploadUrl(previewDoc.docUrl);
                if (!resolvedUrl || previewDoc.docUrl === '#') {
                  return (
                    <div className="h-full min-h-[400px] flex flex-col items-center justify-center bg-gradient-to-br from-slate-50 to-gray-100 rounded-2xl border-2 border-dashed border-gray-200">
                      <FileText size={32} className="text-slate-400 mb-3" />
                      <p className="font-bold text-gray-700 text-sm">{previewDoc.label}</p>
                      <p className="text-xs text-gray-400 mt-1 mb-4">No document file available</p>
                      <div className="flex gap-2">
                        {previewDoc.status !== 'approved' && (
                          <button onClick={() => updateDocStatus(previewDoc.id, 'approved')}
                            className="flex items-center gap-1.5 text-xs font-semibold bg-emerald-600 text-white px-4 py-2 rounded-xl hover:bg-emerald-700 transition-colors">
                            <CheckCircle size={13} /> Approve
                          </button>
                        )}
                        {previewDoc.status !== 'rejected' && (
                          <button onClick={() => { setPreviewDoc(null); setRejectTarget(previewDoc.id); }}
                            className="flex items-center gap-1.5 text-xs font-semibold bg-red-500 text-white px-4 py-2 rounded-xl hover:bg-red-600 transition-colors">
                            <XCircle size={13} /> Reject
                          </button>
                        )}
                      </div>
                    </div>
                  );
                }
                if (resolvedUrl.match(/\.(pdf)$/i)) {
                  return <iframe src={resolvedUrl} className="w-full h-full min-h-[500px] rounded-xl border border-gray-200" title={previewDoc.label} />;
                }
                return <img src={resolvedUrl} alt={previewDoc.label} className="max-w-full mx-auto rounded-xl border border-gray-200 shadow-sm" onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }} />;
              })()}
            </div>

            {/* Footer Actions */}
            {previewDoc.docUrl && previewDoc.docUrl !== '#' && resolveUploadUrl(previewDoc.docUrl) && (
              <div className="flex items-center justify-end gap-3 px-6 py-4 border-t border-gray-100 flex-shrink-0">
            {previewDoc.status !== 'approved' && (
                  <button onClick={() => updateDocStatus(previewDoc.id, 'approved')}
                    className="flex items-center gap-1.5 text-sm font-semibold bg-emerald-600 text-white px-5 py-2.5 rounded-xl hover:bg-emerald-700 transition-colors">
                    <CheckCircle size={14} /> Approve
                  </button>
                )}
                {previewDoc.status !== 'rejected' && (
                  <button onClick={() => { setPreviewDoc(null); setRejectTarget(previewDoc.id); }}
                    className="flex items-center gap-1.5 text-sm font-semibold bg-red-500 text-white px-5 py-2.5 rounded-xl hover:bg-red-600 transition-colors">
                    <XCircle size={14} /> Reject
                  </button>
                )}
              </div>
            )}
          </div>
        </div>
      )}

      {/* Reject Modal */}
      {rejectTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={() => setRejectTarget(null)} />
          <div className="relative bg-white rounded-2xl shadow-card-xl w-full max-w-md animate-scale-in">
            <div className="px-6 py-5 border-b border-gray-100">
              <h2 className="font-bold text-gray-900">Reject Document</h2>
              <p className="text-sm text-gray-500 mt-0.5">Provide a reason so the supplier knows what to fix</p>
            </div>
            <div className="p-6 space-y-4">
              <div>
                <label className="label">Rejection Reason</label>
                <textarea value={rejectReason} onChange={(e) => setRejectReason(e.target.value)}
                  className="input resize-none" rows={3}
                  placeholder="e.g. Document is expired, illegible, or incorrect type..." />
              </div>
              <div className="flex gap-3 justify-end">
                <button onClick={() => setRejectTarget(null)} className="btn-secondary">Cancel</button>
                <button
                  onClick={() => updateDocStatus(rejectTarget, 'rejected', rejectReason)}
                  disabled={!rejectReason.trim()} className="btn-danger">
                  Reject Document
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
