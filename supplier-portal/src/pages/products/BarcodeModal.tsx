import { useEffect, useState } from 'react';
import { X, Printer, Download, Loader2, Barcode, CheckCircle2, Clock, XCircle, Package, Tag, Layers, ShieldCheck } from 'lucide-react';
import type { Product } from '../../types';
import { productsApi } from '../../services/api';

interface BarcodeData {
  barcode:     string;
  barcodeSvg:  string;
  productName: string;
  sku:         string;
}

interface Props {
  product: Product;
  onClose: () => void;
}

// ── Local EAN-13 fallback ─────────────────────────────────────────────────────
function calcCheck(d11: string): string {
  let sum = 0;
  for (let i = 0; i < 11; i++) sum += parseInt(d11[i]) * (i % 2 === 0 ? 1 : 3);
  const r = sum % 10;
  return (r === 0 ? 0 : 10 - r).toString();
}

function buildSvg(ean13: string): string {
  const L = ['0001101','0011001','0010011','0111101','0100011','0110001','0101111','0111011','0110111','0001011'];
  const G = ['0100111','0110011','0011011','0100001','0011101','0111001','0000101','0010001','0001001','0010111'];
  const R = ['1110010','1100110','1101100','1000010','1011100','1001110','1010000','1000100','1001000','1110100'];
  const P = ['LLLLLL','LLGLGG','LLGGLG','LLGGGL','LGLLGG','LGGLLG','LGGGLL','LGLGLG','LGLGGL','LGGLGL'];
  const first = parseInt(ean13[0]);
  const par = P[first];
  let bits = '101';
  for (let i = 1; i <= 6; i++) { const d = parseInt(ean13[i]); bits += par[i-1] === 'L' ? L[d] : G[d]; }
  bits += '01010';
  for (let i = 7; i <= 12; i++) bits += R[parseInt(ean13[i])];
  bits += '101';
  const bw = 2, bh = 80, qz = 10, fs = 11, th = 16;
  const tw = bits.length * bw + qz * 2, totalH = bh + th;
  let rects = '';
  for (let i = 0; i < bits.length; i++)
    if (bits[i] === '1') rects += `<rect x="${qz + i * bw}" y="0" width="${bw}" height="${bh}" fill="#000"/>`;
  const ty = bh + fs + 2;
  const lx = qz + (3 + 21) * bw;
  const rx = qz + (3 + 42 + 5 + 21) * bw;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${tw}" height="${totalH}" viewBox="0 0 ${tw} ${totalH}"><rect width="${tw}" height="${totalH}" fill="white"/>${rects}<text x="${qz-2}" y="${ty}" font-family="monospace" font-size="${fs}" text-anchor="middle">${ean13[0]}</text><text x="${lx}" y="${ty}" font-family="monospace" font-size="${fs}" text-anchor="middle" letter-spacing="1">${ean13.slice(1,7)}</text><text x="${rx}" y="${ty}" font-family="monospace" font-size="${fs}" text-anchor="middle" letter-spacing="1">${ean13.slice(7)}</text></svg>`;
}

function generateLocal(product: Product): BarcodeData {
  const seed = Math.abs(
    product.sku.split('').reduce((a, c) => a + c.charCodeAt(0), 0) * 97 +
    product.id.split('').reduce((a, c) => a + c.charCodeAt(0), 0)
  ) % 100_000_000_000;
  const d11   = seed.toString().padStart(11, '0').slice(0, 11);
  const ean13 = d11 + calcCheck(d11);
  return { barcode: ean13, barcodeSvg: buildSvg(ean13), productName: product.name, sku: product.sku };
}
// ─────────────────────────────────────────────────────────────────────────────

export default function BarcodeModal({ product, onClose }: Props) {
  const [data,    setData]    = useState<BarcodeData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    productsApi.getBarcode(product.id)
      .then((res: any) => {
        const d = res.data ?? res;
        setData({ barcode: d.barcode, barcodeSvg: d.barcodeSvg, productName: d.productName, sku: d.sku });
      })
      .catch(() => setData(generateLocal(product)))
      .finally(() => setLoading(false));
  }, [product]);

  // ── Verification status config ──────────────────────────────────────────────
  const statusMap = {
    active: {
      icon: <CheckCircle2 size={14} className="text-emerald-600" />,
      label: 'Verified & Active',
      bg: 'bg-emerald-50 border-emerald-200 text-emerald-700',
    },
    pending_approval: {
      icon: <Clock size={14} className="text-amber-500" />,
      label: 'Pending Approval',
      bg: 'bg-amber-50 border-amber-200 text-amber-700',
    },
    archived: {
      icon: <XCircle size={14} className="text-gray-400" />,
      label: 'Archived',
      bg: 'bg-gray-100 border-gray-200 text-gray-500',
    },
    draft: {
      icon: <Clock size={14} className="text-blue-500" />,
      label: 'Draft',
      bg: 'bg-blue-50 border-blue-200 text-blue-700',
    },
  };

  const status = statusMap[product.status as keyof typeof statusMap] ?? statusMap.pending_approval;

  // ── Print ───────────────────────────────────────────────────────────────────
  function handlePrint() {
    if (!data) return;
    const win = window.open('', '_blank', 'width=480,height=520');
    if (!win) return;
    win.document.write(`
      <html><head><title>Barcode – ${data.productName}</title>
      <style>
        body { font-family: sans-serif; padding: 32px; max-width: 400px; margin: 0 auto; }
        .header { display:flex; align-items:center; gap:12px; margin-bottom:20px; border-bottom:1px solid #e5e7eb; padding-bottom:16px; }
        img  { width:64px; height:64px; object-fit:cover; border-radius:10px; background:#f3f4f6; }
        h2   { margin:0; font-size:16px; color:#111; }
        .sku { margin:2px 0 0; font-size:12px; color:#6b7280; font-family:monospace; }
        .status { display:inline-flex; align-items:center; gap:4px; font-size:11px; font-weight:700;
                  padding:3px 10px; border-radius:20px; margin-top:6px;
                  background:${product.status === 'active' ? '#d1fae5' : '#fef3c7'};
                  color:${product.status === 'active' ? '#065f46' : '#92400e'}; }
        .barcode { text-align:center; margin:20px 0; }
        .num { font-family:monospace; font-size:15px; font-weight:bold; letter-spacing:3px; color:#111; }
        .details { display:grid; grid-template-columns:1fr 1fr; gap:8px; margin-top:16px; font-size:12px; }
        .detail-item { background:#f9fafb; border-radius:8px; padding:8px 12px; }
        .detail-label { color:#9ca3af; font-size:10px; text-transform:uppercase; letter-spacing:.5px; }
        .detail-value { color:#111; font-weight:700; margin-top:2px; }
      </style></head><body>
      <div class="header">
        ${product.imageUrl ? `<img src="${product.imageUrl}" alt="${product.name}" />` : ''}
        <div>
          <h2>${data.productName}</h2>
          <p class="sku">SKU: ${data.sku}</p>
          <span class="status">${product.status === 'active' ? '✓ Verified & Active' : '⏳ Pending Approval'}</span>
        </div>
      </div>
      <div class="barcode">
        ${data.barcodeSvg}
        <p class="num">${data.barcode}</p>
        <p style="color:#9ca3af;font-size:11px;margin:4px 0 0">EAN-13</p>
      </div>
      <div class="details">
        <div class="detail-item"><div class="detail-label">Price</div><div class="detail-value">R${product.price.toFixed(2)}</div></div>
        <div class="detail-item"><div class="detail-label">Stock</div><div class="detail-value">${product.stockQuantity} units</div></div>
        <div class="detail-item"><div class="detail-label">Min Order</div><div class="detail-value">${product.minOrderQty} units</div></div>
        <div class="detail-item"><div class="detail-label">Category</div><div class="detail-value">${product.categoryName || '—'}</div></div>
      </div>
      <script>window.onload=()=>{window.print();window.close();}<\/script>
      </body></html>`);
    win.document.close();
  }

  function handleDownload() {
    if (!data) return;
    const blob = new Blob([data.barcodeSvg], { type: 'image/svg+xml' });
    const url  = URL.createObjectURL(blob);
    const a    = document.createElement('a');
    a.href     = url;
    a.download = `barcode-${data.sku}.svg`;
    a.click();
    URL.revokeObjectURL(url);
  }

  return (
    <>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6">
        <div className="absolute inset-0 bg-black/50 backdrop-blur-sm animate-fade-in" onClick={onClose} />

        <div
          className="relative bg-white rounded-2xl shadow-card-lg w-full max-w-md max-h-[90vh] flex flex-col overflow-hidden animate-scale-in"
        >
          {/* Header */}
          <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100 bg-gray-50">
            <div className="flex items-center gap-2">
              <div className="w-7 h-7 bg-indigo-50 rounded-lg flex items-center justify-center">
                <Barcode size={14} className="text-indigo-600" />
              </div>
              <span className="font-bold text-gray-900 text-sm">Product Barcode</span>
            </div>
            <button onClick={onClose} className="w-7 h-7 flex items-center justify-center rounded-lg hover:bg-gray-200 transition-colors">
              <X size={15} className="text-gray-500" />
            </button>
          </div>

          <div className="p-5 space-y-4 overflow-y-auto flex-1 overscroll-contain">
            {loading ? (
              <div className="flex flex-col items-center gap-3 py-12">
                <Loader2 size={28} className="text-indigo-600 animate-spin" />
                <p className="text-sm text-gray-500 font-medium">Generating barcode...</p>
              </div>
            ) : data ? (
              <>
                {/* ── Product Details Card ── */}
                <div className="flex items-center gap-4 p-4 bg-gray-50 rounded-2xl border border-gray-100">
                  {/* Image */}
                  <div className="w-16 h-16 rounded-xl overflow-hidden bg-gray-100 flex-shrink-0 border border-gray-200">
                    {product.imageUrl ? (
                      <img src={product.imageUrl} alt={product.name} className="w-full h-full object-cover" />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center">
                        <Package size={24} className="text-gray-300" />
                      </div>
                    )}
                  </div>

                  {/* Info */}
                  <div className="flex-1 min-w-0">
                    <p className="font-bold text-gray-900 text-sm truncate">{product.name}</p>
                    <p className="text-xs text-gray-400 font-mono mt-0.5">SKU: {product.sku}</p>
                    {product.categoryName && (
                      <p className="text-xs text-gray-400 mt-0.5">{product.categoryName}</p>
                    )}
                    {/* Verification badge */}
                    <div className={`inline-flex items-center gap-1.5 mt-2 px-2.5 py-1 rounded-full border text-xs font-bold ${status.bg}`}>
                      {status.icon}
                      {status.label}
                    </div>
                  </div>
                </div>

                {/* ── Product Stats Row ── */}
                <div className="grid grid-cols-3 gap-2">
                  <div className="bg-gray-50 rounded-xl p-3 border border-gray-100 text-center">
                    <div className="flex items-center justify-center gap-1 mb-1">
                      <Tag size={11} className="text-gray-400" />
                      <span className="text-[10px] text-gray-400 uppercase tracking-wide font-semibold">Price</span>
                    </div>
                    <p className="font-black text-gray-900 text-sm">R{product.price.toFixed(2)}</p>
                  </div>
                  <div className="bg-gray-50 rounded-xl p-3 border border-gray-100 text-center">
                    <div className="flex items-center justify-center gap-1 mb-1">
                      <Layers size={11} className="text-gray-400" />
                      <span className="text-[10px] text-gray-400 uppercase tracking-wide font-semibold">Stock</span>
                    </div>
                    <p className={`font-black text-sm ${product.stockQuantity === 0 ? 'text-red-500' : 'text-gray-900'}`}>
                      {product.stockQuantity}
                    </p>
                  </div>
                  <div className="bg-gray-50 rounded-xl p-3 border border-gray-100 text-center">
                    <div className="flex items-center justify-center gap-1 mb-1">
                      <ShieldCheck size={11} className="text-gray-400" />
                      <span className="text-[10px] text-gray-400 uppercase tracking-wide font-semibold">Min Qty</span>
                    </div>
                    <p className="font-black text-gray-900 text-sm">{product.minOrderQty}</p>
                  </div>
                </div>

                {/* ── Barcode ── */}
                <div className="bg-white border-2 border-gray-100 rounded-2xl p-4">
                  <div
                    className="flex justify-center"
                    dangerouslySetInnerHTML={{ __html: data.barcodeSvg }}
                  />
                  <p className="text-center font-mono text-sm font-bold text-gray-800 tracking-[0.2em] mt-2">
                    {data.barcode}
                  </p>
                  <p className="text-center text-[10px] text-gray-400 mt-0.5 uppercase tracking-widest">EAN-13 Barcode</p>
                </div>

                {/* ── Actions ── */}
                <div className="flex gap-2 pt-1">
                  <button
                    onClick={handlePrint}
                    className="flex-1 flex items-center justify-center gap-2 py-2.5 bg-indigo-600 text-white text-sm font-bold rounded-xl hover:bg-indigo-700 transition-colors"
                  >
                    <Printer size={14} /> Print
                  </button>
                  <button
                    onClick={handleDownload}
                    className="flex-1 flex items-center justify-center gap-2 py-2.5 bg-white border border-gray-200 text-gray-700 text-sm font-bold rounded-xl hover:border-indigo-400 hover:text-indigo-600 transition-colors"
                  >
                    <Download size={14} /> Download SVG
                  </button>
                </div>
              </>
            ) : (
              <p className="text-center text-sm text-gray-500 py-8">Failed to load barcode.</p>
            )}
          </div>
        </div>
      </div>

    </>
  );
}
