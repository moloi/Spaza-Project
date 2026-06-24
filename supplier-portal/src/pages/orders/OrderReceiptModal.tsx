import { Printer, X, Download } from 'lucide-react';
import { format } from 'date-fns';
import type { Order } from '../../types';

interface Props {
  order: Order;
  onClose: () => void;
}

export default function OrderReceiptModal({ order, onClose }: Props) {
  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm animate-fade-in" onClick={onClose} />
      <div className="relative bg-white rounded-2xl shadow-card-lg w-full max-w-lg animate-slide-up">
        {/* Header bar (hidden in print) */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100 print:hidden">
          <h2 className="text-base font-bold text-gray-900">Order Receipt</h2>
          <div className="flex items-center gap-2">
            <button
              onClick={handlePrint}
              className="btn-icon hover:text-primary hover:bg-primary-50"
              title="Print Receipt"
            >
              <Printer size={18} />
            </button>
            <button onClick={onClose} className="btn-icon">
              <X size={18} />
            </button>
          </div>
        </div>

        {/* Receipt Content */}
        <div className="overflow-y-auto max-h-[80vh] p-6" id="receipt-content">
          <div className="space-y-5">
            {/* Branding */}
            <div className="text-center pb-4 border-b border-dashed border-gray-300">
              <div className="w-12 h-12 bg-green-50 rounded-xl flex items-center justify-center mx-auto mb-3">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" className="text-green-700">
                  <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V9z" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  <polyline points="9,22 9,12 15,12 15,22" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              </div>
              <h3 className="text-xl font-bold text-green-800">SpazaSure</h3>
              <p className="text-[10px] font-semibold text-gray-400 uppercase tracking-[3px] mt-1">Order Receipt</p>
            </div>

            {/* Order Number & Date */}
            <div className="flex justify-between items-start border-b border-dashed border-gray-300 pb-4">
              <div>
                <p className="text-[10px] font-semibold text-gray-400 uppercase">Order #</p>
                <p className="text-sm font-mono font-bold text-gray-900">{order.orderNumber}</p>
              </div>
              <div className="text-right">
                <p className="text-[10px] font-semibold text-gray-400 uppercase">Date</p>
                <p className="text-sm font-mono font-bold text-gray-900">
                  {format(new Date(order.createdAt), 'dd MMM yyyy')}
                </p>
                <p className="text-xs font-mono text-gray-500">
                  {format(new Date(order.createdAt), 'HH:mm')}
                </p>
              </div>
            </div>

            {/* Buyer Info */}
            <div className="border-b border-dashed border-gray-300 pb-4">
              <p className="text-[10px] font-semibold text-gray-400 uppercase mb-2">Buyer</p>
              <p className="text-sm font-semibold text-gray-900">{order.shopName}</p>
              {order.shopAddress && (
                <p className="text-xs text-gray-500 mt-0.5">{order.shopAddress}</p>
              )}
              <p className="text-xs text-gray-400 mt-1 capitalize">{order.deliveryOption} delivery</p>
            </div>

            {/* Items Table */}
            <div className="border-b border-dashed border-gray-300 pb-4">
              <p className="text-[10px] font-semibold text-gray-400 uppercase mb-3">Items</p>
              <table className="w-full text-xs">
                <thead>
                  <tr className="border-b border-gray-100">
                    <th className="text-left py-1.5 font-semibold text-gray-500">Item</th>
                    <th className="text-center py-1.5 font-semibold text-gray-500 w-12">Qty</th>
                    <th className="text-right py-1.5 font-semibold text-gray-500 w-20">Price</th>
                    <th className="text-right py-1.5 font-semibold text-gray-500 w-20">Total</th>
                  </tr>
                </thead>
                <tbody>
                  {order.items.map((item) => (
                    <tr key={item.productId} className="border-b border-gray-50">
                      <td className="py-2 text-gray-900 font-medium">{item.productName}</td>
                      <td className="py-2 text-center text-gray-600 font-mono">{item.quantity}</td>
                      <td className="py-2 text-right text-gray-600 font-mono">R{item.price.toFixed(2)}</td>
                      <td className="py-2 text-right text-gray-900 font-mono font-semibold">
                        R{(item.quantity * item.price).toFixed(2)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Totals */}
            <div className="border-b border-dashed border-gray-300 pb-4 space-y-1.5">
              <div className="flex justify-between text-xs text-gray-600">
                <span>Subtotal</span>
                <span className="font-mono">R{order.subtotal.toFixed(2)}</span>
              </div>
              <div className="flex justify-between text-xs text-gray-600">
                <span>Delivery Fee</span>
                <span className="font-mono">R{order.deliveryFee.toFixed(2)}</span>
              </div>
              <div className="flex justify-between text-xs text-gray-600">
                <span>Platform Fee</span>
                <span className="font-mono">R{order.platformFee.toFixed(2)}</span>
              </div>
              <div className="flex justify-between text-sm font-bold text-gray-900 pt-2 mt-2 border-t border-gray-200">
                <span>TOTAL</span>
                <span className="font-mono text-green-700">R{order.total.toFixed(2)}</span>
              </div>
            </div>

            {/* Payment & Status */}
            <div className="border-b border-dashed border-gray-300 pb-4 space-y-2">
              <div className="flex justify-between text-xs">
                <span className="text-gray-500">Payment Method</span>
                <span className="font-semibold text-gray-900 uppercase">{order.paymentMethod}</span>
              </div>
              <div className="flex justify-between text-xs">
                <span className="text-gray-500">Payment Status</span>
                <span className="font-semibold text-gray-900 capitalize">
                  {order.paymentStatus === 'held' ? 'Held in Escrow' : order.paymentStatus}
                </span>
              </div>
              <div className="flex justify-between text-xs">
                <span className="text-gray-500">Order Status</span>
                <span className="font-semibold text-gray-900 capitalize">{order.status}</span>
              </div>
            </div>

            {/* Footer */}
            <div className="text-center pt-2">
              <p className="text-sm font-semibold text-gray-700">Thank you for your order!</p>
              <p className="text-[10px] text-gray-400 mt-1">SpazaSure — Empowering Spaza Shops</p>
            </div>
          </div>
        </div>

        {/* Action buttons (hidden in print) */}
        <div className="px-6 py-4 border-t border-gray-100 flex gap-3 print:hidden">
          <button
            onClick={handlePrint}
            className="btn-primary flex-1 flex items-center justify-center gap-2"
          >
            <Printer size={16} /> Print Receipt
          </button>
          <button
            onClick={onClose}
            className="btn-secondary flex-1 flex items-center justify-center gap-2"
          >
            <Download size={16} /> Download PDF
          </button>
        </div>
      </div>
    </div>
  );
}
