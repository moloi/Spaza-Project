import type { Product, Order, AnalyticsSummary, RevenueDataPoint, TopProduct, SupplierProfile } from '../types';

// ─── Admin Mock Data ──────────────────────────────────────────────────────────
export interface AdminSupplier {
  id: string;
  companyName: string;
  contactName: string;
  email: string;
  phone: string;
  tier: 'basic' | 'bronze' | 'silver' | 'gold';
  isVerified: boolean;
  joinedAt: string;
  totalOrders: number;
  totalRevenue: number;
  documents: {
    docType: string;
    label: string;
    status: 'pending' | 'approved' | 'rejected';
    uploadedAt: string;
    expiryDate?: string;
    docUrl: string;
  }[];
}

export const mockAdminSuppliers: AdminSupplier[] = [
  {
    id: 'sup-001', companyName: 'Fresh Foods SA (Pty) Ltd', contactName: 'Thabo Nkosi',
    email: 'thabo@freshfoodssa.co.za', phone: '+27 82 123 4567', tier: 'silver',
    isVerified: true, joinedAt: '2024-11-01', totalOrders: 127, totalRevenue: 48750,
    documents: [
      { docType: 'cipc_certificate', label: 'CIPC Certificate',    status: 'approved', uploadedAt: '2024-11-05', docUrl: '#' },
      { docType: 'tax_clearance',    label: 'Tax Clearance',        status: 'approved', uploadedAt: '2024-11-05', expiryDate: '2025-12-31', docUrl: '#' },
      { docType: 'bee_certificate',  label: 'BEE Certificate',      status: 'pending',  uploadedAt: '2025-01-18', docUrl: '#' },
    ],
  },
  {
    id: 'sup-002', companyName: 'Kasi Wholesale (Pty) Ltd', contactName: 'Nomsa Dlamini',
    email: 'nomsa@kasiwholesale.co.za', phone: '+27 73 456 7890', tier: 'bronze',
    isVerified: false, joinedAt: '2025-01-10', totalOrders: 34, totalRevenue: 12400,
    documents: [
      { docType: 'cipc_certificate', label: 'CIPC Certificate',    status: 'pending',  uploadedAt: '2025-01-12', docUrl: '#' },
      { docType: 'tax_clearance',    label: 'Tax Clearance',        status: 'pending',  uploadedAt: '2025-01-12', docUrl: '#' },
      { docType: 'bee_certificate',  label: 'BEE Certificate',      status: 'rejected', uploadedAt: '2025-01-13', docUrl: '#' },
      { docType: 'product_license',  label: 'Product License',      status: 'pending',  uploadedAt: '2025-01-14', docUrl: '#' },
    ],
  },
  {
    id: 'sup-003', companyName: 'Ubuntu Distributors CC', contactName: 'Sipho Zulu',
    email: 'sipho@ubuntudist.co.za', phone: '+27 61 789 0123', tier: 'basic',
    isVerified: false, joinedAt: '2025-01-20', totalOrders: 5, totalRevenue: 1850,
    documents: [
      { docType: 'cipc_certificate', label: 'CIPC Certificate', status: 'pending', uploadedAt: '2025-01-21', docUrl: '#' },
    ],
  },
  {
    id: 'sup-004', companyName: 'Mzansi Goods Ltd', contactName: 'Lerato Mokoena',
    email: 'lerato@mzansigoods.co.za', phone: '+27 84 321 6540', tier: 'gold',
    isVerified: true, joinedAt: '2024-08-15', totalOrders: 412, totalRevenue: 187500,
    documents: [
      { docType: 'cipc_certificate', label: 'CIPC Certificate', status: 'approved', uploadedAt: '2024-08-20', docUrl: '#' },
      { docType: 'tax_clearance',    label: 'Tax Clearance',    status: 'approved', uploadedAt: '2024-08-20', expiryDate: '2025-08-31', docUrl: '#' },
      { docType: 'bee_certificate',  label: 'BEE Certificate',  status: 'approved', uploadedAt: '2024-08-20', docUrl: '#' },
      { docType: 'product_license',  label: 'Product License',  status: 'approved', uploadedAt: '2024-08-20', docUrl: '#' },
    ],
  },
];

export interface AdminSpazaOwner {
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
  documents: {
    docType: string;
    label: string;
    status: 'pending' | 'approved' | 'rejected';
    uploadedAt: string;
    expiryDate?: string;
    docUrl: string;
  }[];
}

export const mockAdminSpazaOwners: AdminSpazaOwner[] = [
  {
    id: 'spz-001', shopName: "Mama's Spaza", ownerName: 'Lindiwe Mkhize',
    email: 'lindiwe@mamasspaza.co.za', phone: '+27 71 234 5678', location: 'Soweto, Johannesburg',
    isVerified: true, joinedAt: '2024-09-15', totalOrders: 85, totalSpent: 32400,
    documents: [
      { docType: 'business_permit', label: 'Business Permit', status: 'approved', uploadedAt: '2024-09-18', docUrl: '#' },
      { docType: 'id_document', label: 'ID Document', status: 'approved', uploadedAt: '2024-09-18', docUrl: '#' },
    ],
  },
  {
    id: 'spz-002', shopName: 'Zulu Corner Shop', ownerName: 'Bongani Zulu',
    email: 'bongani@zulucorner.co.za', phone: '+27 63 456 7891', location: 'Khayelitsha, Cape Town',
    isVerified: true, joinedAt: '2024-10-20', totalOrders: 64, totalSpent: 24800,
    documents: [
      { docType: 'business_permit', label: 'Business Permit', status: 'approved', uploadedAt: '2024-10-22', docUrl: '#' },
      { docType: 'id_document', label: 'ID Document', status: 'approved', uploadedAt: '2024-10-22', docUrl: '#' },
      { docType: 'proof_of_address', label: 'Proof of Address', status: 'approved', uploadedAt: '2024-10-22', docUrl: '#' },
    ],
  },
  {
    id: 'spz-003', shopName: 'Ndlovu General', ownerName: 'Sipho Ndlovu',
    email: 'sipho@ndlovugeneral.co.za', phone: '+27 72 789 0124', location: 'Durban North',
    isVerified: false, joinedAt: '2025-01-05', totalOrders: 12, totalSpent: 4500,
    documents: [
      { docType: 'business_permit', label: 'Business Permit', status: 'pending', uploadedAt: '2025-01-06', docUrl: '#' },
      { docType: 'id_document', label: 'ID Document', status: 'approved', uploadedAt: '2025-01-06', docUrl: '#' },
    ],
  },
  {
    id: 'spz-004', shopName: 'Khumalo Spaza', ownerName: 'Thandi Khumalo',
    email: 'thandi@khumalospaza.co.za', phone: '+27 84 321 6541', location: 'Tembisa, Ekurhuleni',
    isVerified: false, joinedAt: '2025-01-18', totalOrders: 3, totalSpent: 1200,
    documents: [
      { docType: 'business_permit', label: 'Business Permit', status: 'pending', uploadedAt: '2025-01-19', docUrl: '#' },
      { docType: 'id_document', label: 'ID Document', status: 'pending', uploadedAt: '2025-01-19', docUrl: '#' },
      { docType: 'proof_of_address', label: 'Proof of Address', status: 'pending', uploadedAt: '2025-01-19', docUrl: '#' },
    ],
  },
  {
    id: 'spz-005', shopName: 'Bongani Shop', ownerName: 'Bongani Sithole',
    email: 'bongani@bonganishop.co.za', phone: '+27 60 555 1234', location: 'Mitchells Plain, Cape Town',
    isVerified: true, joinedAt: '2024-08-01', totalOrders: 142, totalSpent: 58900,
    documents: [
      { docType: 'business_permit', label: 'Business Permit', status: 'approved', uploadedAt: '2024-08-03', docUrl: '#' },
      { docType: 'id_document', label: 'ID Document', status: 'approved', uploadedAt: '2024-08-03', docUrl: '#' },
      { docType: 'proof_of_address', label: 'Proof of Address', status: 'approved', uploadedAt: '2024-08-03', docUrl: '#' },
    ],
  },
];

export const mockAdminStats = {
  totalSuppliers: 4,
  pendingVerifications: 2,
  pendingDocuments: 5,
  totalRevenue: 250500,
  activeProducts: 148,
  totalOrders: 578,
};

export const mockAdminRevenue: RevenueDataPoint[] = [
  { month: 'Aug', revenue: 112000, orders: 289 },
  { month: 'Sep', revenue: 138000, orders: 341 },
  { month: 'Oct', revenue: 125000, orders: 312 },
  { month: 'Nov', revenue: 178000, orders: 445 },
  { month: 'Dec', revenue: 165000, orders: 410 },
  { month: 'Jan', revenue: 250500, orders: 578 },
];

export interface AdminNotification {
  id: string;
  type: 'system' | 'compliance' | 'order' | 'supplier';
  title: string;
  message: string;
  sentTo: 'all' | 'suppliers' | 'specific';
  createdAt: string;
  read: boolean;
  priority: 'high' | 'normal';
}

export const mockAdminNotifications: AdminNotification[] = [
  { id: 'an1', type: 'compliance', title: 'BEE Certificate Reminder',    message: 'Reminder sent to 3 suppliers with expiring BEE certificates.',         sentTo: 'suppliers', createdAt: new Date(Date.now() - 1000*60*30).toISOString(),       read: false, priority: 'high' },
  { id: 'an2', type: 'system',     title: 'Platform Maintenance',        message: 'Scheduled maintenance on 25 Jan 2025 from 02:00–04:00 SAST.',          sentTo: 'all',       createdAt: new Date(Date.now() - 1000*60*60*3).toISOString(),     read: false, priority: 'high' },
  { id: 'an3', type: 'supplier',   title: 'New Supplier Registered',     message: 'Ubuntu Distributors CC has registered and is awaiting verification.',  sentTo: 'specific',  createdAt: new Date(Date.now() - 1000*60*60*6).toISOString(),     read: true,  priority: 'normal' },
  { id: 'an4', type: 'order',      title: 'High Value Order Alert',      message: 'Order ORD-2025-0009 totalling R12,450 placed by Mzansi Spaza Hub.',   sentTo: 'specific',  createdAt: new Date(Date.now() - 1000*60*60*24).toISOString(),    read: true,  priority: 'normal' },
  { id: 'an5', type: 'system',     title: 'Monthly Report Ready',        message: 'January 2025 platform report is ready for download.',                  sentTo: 'all',       createdAt: new Date(Date.now() - 1000*60*60*48).toISOString(),    read: true,  priority: 'normal' },
];

export const mockProfile: SupplierProfile = {
  id: 'sup-001',
  companyName: 'Fresh Foods SA (Pty) Ltd',
  registrationNumber: '2020/123456/07',
  taxNumber: '9876543210',
  contactName: 'Thabo Nkosi',
  email: 'thabo@freshfoodssa.co.za',
  phone: '+27 82 123 4567',
  address: '12 Industrial Road, Johannesburg, 2001',
  tier: 'silver',
  isVerified: true,
  bankName: 'FNB',
  bankAccount: '62*****890',
  bankBranchCode: '250655',
  documents: [
    { id: 'd1', docType: 'cipc_certificate', docUrl: '#', status: 'approved' },
    { id: 'd2', docType: 'tax_clearance', docUrl: '#', status: 'approved', expiryDate: '2025-12-31' },
    { id: 'd3', docType: 'bee_certificate', docUrl: '#', status: 'pending' },
  ],
};

export const mockProducts: Product[] = [
  { id: 'p1', name: 'Sunflower Oil 2L',    description: 'Premium sunflower cooking oil', sku: 'OIL-SUN-2L',   price: 45.99, imageUrl: 'https://placehold.co/200x200?text=Oil',   images: [], categoryId: 'c1', categoryName: 'Cooking Oils',       supplierId: 'sup-001', supplierName: 'Fresh Foods SA',      stockQuantity: 500, minOrderQty: 12, qrCode: 'QR-p1', isAvailable: true,  status: 'active',           rating: 4.5, reviewCount: 23, createdAt: '2025-01-10' },
  { id: 'p2', name: 'Maize Meal 5kg',      description: 'White maize meal',             sku: 'MEAL-MAZ-5K',  price: 62.50, imageUrl: 'https://placehold.co/200x200?text=Meal',  images: [], categoryId: 'c2', categoryName: 'Grains & Cereals',   supplierId: 'sup-001', supplierName: 'Fresh Foods SA',      stockQuantity: 300, minOrderQty: 6,  qrCode: 'QR-p2', isAvailable: true,  status: 'active',           rating: 4.8, reviewCount: 41, createdAt: '2025-01-12' },
  { id: 'p3', name: 'Sugar 2kg',           description: 'White granulated sugar',       sku: 'SUG-WHT-2K',   price: 38.00, imageUrl: 'https://placehold.co/200x200?text=Sugar', images: [], categoryId: 'c3', categoryName: 'Sugar & Sweeteners', supplierId: 'sup-001', supplierName: 'Fresh Foods SA',      stockQuantity: 800, minOrderQty: 12, qrCode: 'QR-p3', isAvailable: true,  status: 'active',           rating: 4.2, reviewCount: 18, createdAt: '2025-01-15' },
  { id: 'p4', name: 'Tomato Sauce 500ml',  description: 'Rich tomato sauce',            sku: 'SAU-TOM-500',  price: 22.99, imageUrl: 'https://placehold.co/200x200?text=Sauce', images: [], categoryId: 'c4', categoryName: 'Sauces & Condiments', supplierId: 'sup-001', supplierName: 'Fresh Foods SA',      stockQuantity: 0,   minOrderQty: 24, qrCode: 'QR-p4', isAvailable: false, status: 'active',           rating: 3.9, reviewCount: 7,  createdAt: '2025-01-18' },
  { id: 'p5', name: 'Bulk Rice 10kg',      description: 'Long grain white rice',        sku: 'RIC-LNG-10K',  price: 89.99, imageUrl: 'https://placehold.co/200x200?text=Rice',  images: [], categoryId: 'c2', categoryName: 'Grains & Cereals',   supplierId: 'sup-002', supplierName: 'Kasi Wholesale',      stockQuantity: 200, minOrderQty: 5,  qrCode: 'QR-p5', isAvailable: true,  status: 'pending_approval', rating: 0,   reviewCount: 0,  createdAt: '2025-01-22' },
  { id: 'p6', name: 'Washing Powder 2kg',  description: 'Heavy duty washing powder',    sku: 'CLN-WSH-2K',   price: 55.00, imageUrl: 'https://placehold.co/200x200?text=Wash',  images: [], categoryId: 'c5', categoryName: 'Cleaning',           supplierId: 'sup-002', supplierName: 'Kasi Wholesale',      stockQuantity: 150, minOrderQty: 10, qrCode: 'QR-p6', isAvailable: true,  status: 'pending_approval', rating: 0,   reviewCount: 0,  createdAt: '2025-01-23' },
  { id: 'p7', name: 'Canola Oil 750ml',    description: 'Pure canola cooking oil',      sku: 'OIL-CAN-750',  price: 32.50, imageUrl: 'https://placehold.co/200x200?text=Canola', images: [], categoryId: 'c1', categoryName: 'Cooking Oils',       supplierId: 'sup-004', supplierName: 'Mzansi Goods Ltd',    stockQuantity: 1200,minOrderQty: 24, qrCode: 'QR-p7', isAvailable: true,  status: 'active',           rating: 4.6, reviewCount: 55, createdAt: '2024-09-01' },
  { id: 'p8', name: 'Instant Noodles x5', description: 'Chicken flavour noodles pack',  sku: 'NOD-CHK-5PK',  price: 18.99, imageUrl: 'https://placehold.co/200x200?text=Noodles',images: [], categoryId: 'c6', categoryName: 'Instant Foods',      supplierId: 'sup-004', supplierName: 'Mzansi Goods Ltd',    stockQuantity: 3000,minOrderQty: 48, qrCode: 'QR-p8', isAvailable: true,  status: 'active',           rating: 4.1, reviewCount: 88, createdAt: '2024-09-05' },
];

export const mockOrders: Order[] = [
  { id: 'o1', orderNumber: 'ORD-2025-0001', shopId: 's1', shopName: "Mama's Spaza",    shopAddress: 'Soweto, Johannesburg',    items: [{ productId: 'p1', productName: 'Sunflower Oil 2L',   productImage: '', quantity: 24, price: 45.99 }], subtotal: 1103.76, deliveryFee: 150, platformFee: 33.11, total: 1286.87, status: 'processing', deliveryOption: 'standard', paymentMethod: 'eft',    paymentStatus: 'held',     createdAt: '2025-01-20T09:00:00Z', estimatedDelivery: '2025-01-23' },
  { id: 'o2', orderNumber: 'ORD-2025-0002', shopId: 's2', shopName: 'Zulu Corner Shop', shopAddress: 'Khayelitsha, Cape Town',  items: [{ productId: 'p2', productName: 'Maize Meal 5kg',     productImage: '', quantity: 12, price: 62.50 }], subtotal: 750,     deliveryFee: 200, platformFee: 22.50, total: 972.50,  status: 'pending',    deliveryOption: 'express',  paymentMethod: 'wallet', paymentStatus: 'held',     createdAt: '2025-01-21T11:30:00Z' },
  { id: 'o3', orderNumber: 'ORD-2025-0003', shopId: 's3', shopName: 'Ndlovu General',   shopAddress: 'Durban North',            items: [{ productId: 'p3', productName: 'Sugar 2kg',          productImage: '', quantity: 36, price: 38.00 }], subtotal: 1368,    deliveryFee: 180, platformFee: 41.04, total: 1589.04, status: 'delivered',  deliveryOption: 'standard', paymentMethod: 'eft',    paymentStatus: 'released', createdAt: '2025-01-15T08:00:00Z', estimatedDelivery: '2025-01-18' },
  { id: 'o4', orderNumber: 'ORD-2025-0004', shopId: 's4', shopName: 'Khumalo Spaza',    shopAddress: 'Tembisa, Ekurhuleni',     items: [{ productId: 'p7', productName: 'Canola Oil 750ml',   productImage: '', quantity: 48, price: 32.50 }], subtotal: 1560,    deliveryFee: 160, platformFee: 46.80, total: 1766.80, status: 'dispatched', deliveryOption: 'standard', paymentMethod: 'eft',    paymentStatus: 'held',     createdAt: '2025-01-19T14:00:00Z', estimatedDelivery: '2025-01-22' },
  { id: 'o5', orderNumber: 'ORD-2025-0005', shopId: 's5', shopName: 'Bongani Shop',     shopAddress: 'Mitchells Plain, CT',     items: [{ productId: 'p8', productName: 'Instant Noodles x5', productImage: '', quantity: 96, price: 18.99 }], subtotal: 1823.04, deliveryFee: 220, platformFee: 54.69, total: 2097.73, status: 'cancelled',  deliveryOption: 'express',  paymentMethod: 'wallet', paymentStatus: 'refunded', createdAt: '2025-01-18T10:00:00Z' },
];

export const mockSummary: AnalyticsSummary = {
  totalRevenue: 48750,
  totalOrders: 127,
  activeProducts: 34,
  avgOrderValue: 3839,
  revenueChange: 12.5,
  ordersChange: 8.3,
};

export const mockRevenue: RevenueDataPoint[] = [
  { month: 'Aug', revenue: 28000, orders: 72 },
  { month: 'Sep', revenue: 32000, orders: 85 },
  { month: 'Oct', revenue: 29500, orders: 78 },
  { month: 'Nov', revenue: 41000, orders: 108 },
  { month: 'Dec', revenue: 38000, orders: 99 },
  { month: 'Jan', revenue: 48750, orders: 127 },
];

export const mockTopProducts: TopProduct[] = [
  { productId: 'p1', productName: 'Sunflower Oil 2L', totalSold: 480, revenue: 22075 },
  { productId: 'p2', productName: 'Maize Meal 5kg', totalSold: 312, revenue: 19500 },
  { productId: 'p3', productName: 'Sugar 2kg', totalSold: 288, revenue: 10944 },
];
