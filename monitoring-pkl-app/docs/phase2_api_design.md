# Phase 2 API Design Document: Monitoring PKL System

## 1. Executive Summary & Architectural Scope

This document specifies the technical design, contracts, request payloads, response schemas, and authorization requirements for the subsequent implementation phases (Phase 2) of the School PKL Attendance and Daily Logbook System.

In Phase 1, the database schema (including `attendances`, `activities`, `logbooks`, `logbook_comments`, and `leave_requests`), authentication, role authorization, and master data endpoints were established. Phase 2 introduces:
1. **Attendance Engine:** Live GPS calculation (Haversine formula), location status determination against the 50m default radius, camera photo upload, and field supervisor verification workflows.
2. **Daily Logbook Engine:** Student activity logging, photo evidence, resubmissions on rejection, supervisor approvals, and teacher feedback comments.
3. **Leave Request Workflow:** Student leave filing with medical/permission evidence and supervisor approval synchronization.
4. **Role Dashboards:** Aggregated metrics tailored specifically for Student, Teacher, Field Supervisor, and Admin.

---

## 2. Global Conventions & Standards

- **Base URL:** `/api`
- **Authentication:** Bearer token via Laravel Sanctum (`Authorization: Bearer <token>`)
- **Headers:** `Accept: application/json`, `Content-Type: application/json` (or `multipart/form-data` for file uploads)
- **Timezone:** `Asia/Jakarta` (WIB) strictly enforced for all server timestamps
- **Standard Success Response Format:**
```json
{
  "success": true,
  "message": "Operation description",
  "data": { ... }
}
```
- **Standard Validation Error Format (HTTP 422):**
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "field_name": [
      "The field_name field is required."
    ]
  }
}
```

---

## 3. Attendance Module Endpoints

### 3.1 Student Check-In
- **Endpoint:** `POST /api/student/attendances/check-in`
- **Actor:** `student` (own active placement only)
- **Content-Type:** `multipart/form-data`
- **Request Body:**
  | Field | Type | Rules | Description |
  |---|---|---|---|
  | `latitude` | numeric | required, between:-90,90 | GPS latitude from device |
  | `longitude` | numeric | required, between:-180,180 | GPS longitude from device |
  | `accuracy` | numeric | nullable, min:0 | Device GPS accuracy in meters |
  | `photo` | file | required, image, mimes:jpeg,jpg,png, max:5120 | Live camera selfie capture |

- **Backend Logic:**
  1. Retrieve student's current active placement. Return `422` if no active placement.
  2. Check if attendance already exists for `today` (`placement_id` + `attendance_date`). Return `422` if already checked in.
  3. Calculate distance to placement location coordinates using Haversine formula:
     $$d = 2r \arcsin\left(\sqrt{\sin^2\left(\frac{\Delta\phi}{2}\right) + \cos(\phi_1)\cos(\phi_2)\sin^2\left(\frac{\Delta\lambda}{2}\right)}\right)$$
  4. Compare calculated distance against location radius (default `50m` or custom radius):
     - If $d \le \text{radius}$: `check_in_location_status = 'within_radius'`
     - If $d > \text{radius}$: `check_in_location_status = 'outside_radius'`
  5. Store photo in `storage/app/public/attendances/checkin/{year}/{month}/`.
  6. Create attendance record with `completeness_status = 'in_progress'`, `verification_status = 'pending'`.

- **Success Response (HTTP 201):**
```json
{
  "success": true,
  "message": "Check-in successful",
  "data": {
    "id": 101,
    "attendance_date": "2026-10-20",
    "check_in_time": "07:55:12",
    "check_in_latitude": -6.208763,
    "check_in_longitude": 106.845599,
    "check_in_distance": 18.5,
    "check_in_location_status": "within_radius",
    "check_in_photo_url": "http://localhost:8000/storage/attendances/checkin/2026/10/checkin_101.jpg",
    "completeness_status": "in_progress",
    "verification_status": "pending"
  }
}
```

---

### 3.2 Student Check-Out
- **Endpoint:** `POST /api/student/attendances/check-out`
- **Actor:** `student`
- **Content-Type:** `multipart/form-data`
- **Request Body:**
  | Field | Type | Rules | Description |
  |---|---|---|---|
  | `latitude` | numeric | required, between:-90,90 | GPS latitude from device |
  | `longitude` | numeric | required, between:-180,180 | GPS longitude from device |
  | `accuracy` | numeric | nullable, min:0 | Device GPS accuracy in meters |
  | `photo` | file | required, image, mimes:jpeg,jpg,png, max:5120 | Live camera selfie capture |

- **Backend Logic:**
  1. Retrieve today's attendance record for active placement.
  2. Reject (`422`) if no check-in record exists or check-out is already recorded.
  3. Calculate distance and determine `check_out_location_status`.
  4. Set `completeness_status = 'complete'`.
  5. Store check-out photo in `storage/app/public/attendances/checkout/`.

- **Success Response (HTTP 200):**
```json
{
  "success": true,
  "message": "Check-out successful",
  "data": {
    "id": 101,
    "attendance_date": "2026-10-20",
    "check_in_time": "07:55:12",
    "check_out_time": "17:02:40",
    "check_out_distance": 24.1,
    "check_out_location_status": "within_radius",
    "completeness_status": "complete",
    "verification_status": "pending"
  }
}
```

---

### 3.3 Student Attendance History
- **Endpoint:** `GET /api/student/attendances`
- **Actor:** `student` (own records only)
- **Query Parameters:** `month` (e.g. `2026-10`), `start_date`, `end_date`, `page`, `per_page`
- **Success Response (HTTP 200):**
```json
{
  "success": true,
  "message": "Attendance history retrieved",
  "data": [
    {
      "id": 101,
      "attendance_date": "2026-10-20",
      "check_in_time": "07:55:12",
      "check_out_time": "17:02:40",
      "completeness_status": "complete",
      "check_in_location_status": "within_radius",
      "check_out_location_status": "within_radius",
      "verification_status": "approved",
      "verification_note": "Hadir tepat waktu",
      "has_logbook": true
    }
  ],
  "meta": { "current_page": 1, "last_page": 1, "total": 1 }
}
```

---

### 3.4 Field Supervisor Attendance Verification Queue
- **Endpoint:** `GET /api/supervisor/attendances`
- **Actor:** `field_supervisor` (scoped strictly to assigned placements)
- **Query Parameters:** `status` (`pending`|`approved`|`rejected`), `date`, `student_id`, `per_page`
- **Success Response (HTTP 200):** Paginated list of attendances with student name, NIS, location status, photos, and distance.

---

### 3.5 Field Supervisor Attendance Approval / Rejection
- **Endpoint:** `POST /api/supervisor/attendances/{id}/verify`
- **Actor:** `field_supervisor` (must be assigned to the placement)
- **Request Body:**
```json
{
  "status": "approved",
  "verification_note": "Presensi terverifikasi valid di lokasi kerja."
}
```
- **Rules:** `status` in `['approved', 'rejected']`, `verification_note` required if `rejected`.
- **Backend Logic:** Sets `verification_status`, `verified_by = auth()->id()`, `verified_at = now()`.

---

### 3.6 Field Supervisor Attendance Correction
- **Endpoint:** `POST /api/supervisor/attendances/{id}/correct`
- **Actor:** `field_supervisor`
- **Purpose:** Manually adjust an incomplete attendance (e.g. system timeout or student forgotten check-out approved by supervisor).
- **Request Body:**
```json
{
  "completeness_status": "complete",
  "check_out_time": "17:00:00",
  "correction_reason": "Siswa lupa checkout namun konfirmasi hadir penuh"
}
```

---

### 3.7 Teacher Attendance Monitoring
- **Endpoint:** `GET /api/teacher/attendances`
- **Actor:** `teacher` (scoped strictly to assigned students)
- **Behavior:** Read-only access to attendance records, completeness, and verification status. Teachers cannot approve/reject attendance.

---

## 4. Logbook Module Endpoints

### 4.1 Student Logbook Submission
- **Endpoint:** `POST /api/student/logbooks`
- **Actor:** `student`
- **Content-Type:** `multipart/form-data`
- **Request Body:**
  | Field | Type | Rules | Description |
  |---|---|---|---|
  | `attendance_id` | integer | required, exists:attendances,id | Associated today's attendance |
  | `activity_id` | integer | nullable, exists:activities,id | Predefined activity reference |
  | `title` | string | required, max:255 | Headline of daily task |
  | `description` | string | required, min:20 | Detailed summary of work performed |
  | `start_time` | string (H:i) | required, date_format:H:i | Activity start time |
  | `end_time` | string (H:i) | required, date_format:H:i, after:start_time | Activity finish time |
  | `photo` | file | nullable, image, mimes:jpeg,jpg,png, max:5120 | Photo evidence of completed work |

- **Backend Logic:**
  1. Verify attendance belongs to student's active placement.
  2. Prevent duplicate logbook for the same attendance.
  3. Store documentation image in `storage/app/public/logbooks/`.
  4. Create logbook record with `verification_status = 'pending'`.

---

### 4.2 Student Logbook Resubmission
- **Endpoint:** `PUT /api/student/logbooks/{id}`
- **Actor:** `student` (owner only)
- **Rules:** Can only edit if `verification_status == 'rejected'` or `draft`. If currently `approved`, reject update with HTTP 422.
- **Backend Logic:** Resets `verification_status` to `'pending'`, updates content, and records revision timestamp.

---

### 4.3 Field Supervisor Logbook Verification
- **Endpoint:** `POST /api/supervisor/logbooks/{id}/verify`
- **Actor:** `field_supervisor` (assigned supervisor only)
- **Request Body:**
```json
{
  "status": "approved",
  "verification_note": "Aktivitas perbaikan jaringan dilaksanakan dengan baik."
}
```

---

### 4.4 Teacher Logbook Comments
- **Endpoint:** `POST /api/teacher/logbooks/{id}/comments`
- **Actor:** `teacher` (assigned supervising teacher)
- **Request Body:**
```json
{
  "comment": "Bagus, pastikan dokumentasi kabel UTP juga dicatat pada laporan akhir."
}
```
- **Response:** Appends record to `logbook_comments` table referencing `user_id = teacher->user_id`.

---

### 4.5 Logbook Comments List
- **Endpoint:** `GET /api/logbooks/{id}/comments`
- **Actors:** `student`, `teacher`, `field_supervisor`, `admin`
- **Success Response (HTTP 200):** Threaded or chronological comments showing commenter name, role, timestamp, and message.

---

## 5. Leave Request Module Endpoints

### 5.1 Student Leave Submission
- **Endpoint:** `POST /api/student/leave-requests`
- **Actor:** `student`
- **Content-Type:** `multipart/form-data`
- **Request Body:**
  | Field | Type | Rules | Description |
  |---|---|---|---|
  | `start_date` | date | required, date, after_or_equal:today | Start date of leave |
  | `end_date` | date | required, date, after_or_equal:start_date | End date of leave |
  | `leave_type` | string | required, in:sick,permission | Type of leave |
  | `reason` | string | required, min:10, max:1000 | Explanation for absence |
  | `evidence` | file | required, file, mimes:pdf,jpeg,jpg,png, max:5120 | Doctor's note or official parent letter |

- **Backend Logic:**
  1. Verify active placement.
  2. Ensure no conflicting approved attendance or leave already exists on dates.
  3. Store evidence file in `storage/app/public/leave_evidence/`.
  4. Create `leave_requests` entry with `status = 'pending'`.

---

### 5.2 Field Supervisor Leave Review
- **Endpoint:** `POST /api/supervisor/leave-requests/{id}/review`
- **Actor:** `field_supervisor`
- **Request Body:**
```json
{
  "status": "approved",
  "reviewer_note": "Izin disetujui, semoga lekas sembuh."
}
```
- **Backend Logic:**
  - Upon `approved`, system automatically creates corresponding `attendances` records for each date in range with `completeness_status = 'complete'`, `verification_status = 'approved'`, and notes indicating excused leave (`izin`/`sakit`).

---

## 6. Dashboard Endpoints

### 6.1 Student Dashboard
- **Endpoint:** `GET /api/student/dashboard`
- **Actor:** `student`
- **Response Structure:**
```json
{
  "success": true,
  "data": {
    "placement": {
      "id": 1,
      "location_name": "PT. Maju Bersama",
      "address": "Jl. Sudirman No. 123",
      "latitude": -6.208763,
      "longitude": 106.845599,
      "radius": 50,
      "teacher_name": "Budi Santoso",
      "supervisor_name": "Agus Wijaya"
    },
    "today_attendance": {
      "has_checked_in": true,
      "check_in_time": "07:55:12",
      "has_checked_out": false,
      "check_out_time": null,
      "status": "in_progress",
      "location_status": "within_radius"
    },
    "today_logbook": {
      "submitted": false,
      "status": null
    },
    "statistics": {
      "total_days": 45,
      "present_days": 42,
      "sick_days": 2,
      "permission_days": 1,
      "absent_days": 0,
      "attendance_percentage": 93.3
    }
  }
}
```

---

### 6.2 Teacher Dashboard
- **Endpoint:** `GET /api/teacher/dashboard`
- **Actor:** `teacher`
- **Response Structure:** Total assigned students, count of students checked in today, pending logbooks needing review, students requiring attendance attention (absent or outside radius).

---

### 6.3 Field Supervisor Dashboard
- **Endpoint:** `GET /api/supervisor/dashboard`
- **Actor:** `field_supervisor`
- **Response Structure:** Total supervisees, today's check-ins needing verification, pending logbook approvals count, pending leave requests count.

---

### 6.4 Admin Dashboard
- **Endpoint:** `GET /api/admin/dashboard`
- **Actor:** `admin`
- **Response Structure:** Total active PKL periods, active placements count, active partner industry locations, school-wide real-time attendance rate today, summary of system health.

---

## 7. Storage & File Management Specifications

1. **Storage Disk:** `public` disk (`storage/app/public`)
2. **Directory Structure:**
   - `attendances/checkin/{Y}/{m}/{id}_{hash}.jpg`
   - `attendances/checkout/{Y}/{m}/{id}_{hash}.jpg`
   - `logbooks/{Y}/{m}/{id}_{hash}.jpg`
   - `leave_evidence/{Y}/{m}/{id}_{hash}.pdf`
3. **Public URL Generation:** Uses `Storage::disk('public')->url($path)`
4. **File Validation:** Strict MIME type checking and max 5MB limits enforced via Laravel FormRequests.
