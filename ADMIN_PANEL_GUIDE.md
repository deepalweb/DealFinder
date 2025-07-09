# Admin Panel Guide

## 1. Overview

This document provides a guide to the Admin Panel for the application. The admin panel is a restricted area designed for administrators to manage core aspects of the platform, including users, merchants, and promotions.

- **Access URL:** The admin panel is typically accessed by navigating to `/admin/dashboard` after logging in.
- **Permissions:** Only users with the 'admin' role can access these features. Unauthorized access attempts will be redirected or blocked.

## 2. Key Features

### Dashboard (`/admin/dashboard`)
The admin dashboard provides a quick overview of key platform statistics:
- **Total Users:** Count of all registered users.
- **Total Merchants:** Count of all merchant profiles, with a breakdown by status (e.g., Pending Approval).
- **Total Promotions:** Count of all promotions, with a breakdown by status (e.g., Pending Approval).
- **Quick Links:** Direct links to the detailed management pages for each section.

### User Management (`/admin/users`)
Allows admins to manage user accounts:
- **List Users:** Displays a table of all users with their name, email, and role.
- **Create New User:**
    - Opens a modal form.
    - Fields: Name, Email, Password (required for creation), Role (User, Merchant, Admin).
- **Edit User:**
    - Opens a modal form pre-filled with user data.
    - Editable fields: Name, Email, Role. (Password is not changed via this form).
- **Delete User:**
    - Permanently removes a user account. A confirmation prompt is displayed.

### Merchant Management (`/admin/merchants`)
Allows admins to manage merchant profiles:
- **List Merchants:** Displays a table of all merchants with name, contact info, and current status (e.g., Active, Pending Approval, Rejected).
- **Create New Merchant:**
    - Opens a modal form.
    - Fields: Name, Contact Info, Profile/Description, Address, Contact Number, Status.
    - Optional: Link to an existing User ID to automatically assign that user as the merchant.
- **Edit Merchant / Approve:**
    - Opens a modal form pre-filled with merchant data.
    - All merchant details can be edited, including their `status` (e.g., to approve a pending application, suspend an active merchant, etc.).
- **Delete Merchant:**
    - Permanently removes a merchant profile. Associated users will have their merchant link removed. Confirmation is required.

### Promotion Management (`/admin/promotions`)
Allows admins to manage promotions created by merchants or by admins themselves:
- **List Promotions:** Displays a table of all promotions, including title, associated merchant, current status (e.g., Pending Approval, Active, Expired, Rejected), and start/end dates.
- **Create New Promotion:**
    - Opens a modal form.
    - Fields: Title, Description, Discount info, Promo Code, Category, Associated Merchant (selected from a list), Start Date, End Date, Image URL (optional), Promotion URL (optional), Original Price (optional), Discounted Price (optional), Featured flag, Status.
- **Edit Promotion:**
    - Opens a modal form pre-filled with promotion data.
    - All details can be edited, including the administrative `status`.
- **Quick Status Change:**
    - A dropdown menu is available in the list view for each promotion to quickly change its status (e.g., approve, reject, pause).
- **Delete Promotion:**
    - Permanently removes a promotion. Confirmation is required.

## 3. Technical Notes (for Developers)

### Code Location
- **Frontend Pages:** `frontend/scripts/pages/admin/`
- **Frontend Components:** `frontend/scripts/components/admin/`
- **Backend Route Logic:**
    - Admin-specific capabilities are integrated into:
        - `backend/routes/userRoutes.js`
        - `backend/routes/merchantRoutes.js`
        - `backend/routes/promotionRoutes.js`
    - Dedicated admin-only routes are in: `backend/routes/adminRoutes/` (e.g., `adminPromotionRoutes.js`, `adminDashboardRoutes.js`)

### Key Frontend Components
- **`AdminLayout.js`**: The main wrapper for all admin pages, includes sidebar navigation.
- **`AdminModal.js`**: A reusable modal component used for create/edit forms.
- **`UserForm.js`**: Form for creating/editing users.
- **`MerchantForm.js`**: Form for creating/editing merchants.
- **`PromotionForm.js`**: Form for creating/editing promotions.

### Main Admin API Endpoints
- **Dashboard Stats:** `GET /api/admin/dashboard/stats`
- **Admin List Promotions:** `GET /api/admin/promotions` (supports filtering)
- Standard CRUD endpoints under `/api/users`, `/api/merchants`, `/api/promotions` have authorization checks (`authorizeAdmin`, `authorizeSelfOrAdmin`, etc.) to enable admin actions.

### Authentication & Authorization
- **Frontend:** The `AdminRoute` component in `frontend/scripts/App.js` protects all `/admin/*` routes, relying on `Auth.isAdmin()` from `authHelpers.js`.
- **Backend:** Middleware functions like `authorizeAdmin` in `backend/middleware/auth.js` protect API endpoints.

## 4. Potential Future Enhancements
- Advanced server-side filtering, sorting, and pagination for all management tables.
- Rich text editors for profile/description fields.
- More detailed analytics and charts on the dashboard.
- A more user-friendly way to link Users to Merchants on creation (e.g., user search/selector).
- Audit logs for admin actions.

---
This guide should help administrators use the panel effectively and assist developers in understanding its structure.
