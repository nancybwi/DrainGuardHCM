# Complete Report Flow - DrainGuardHCM

## 📊 Full Report Lifecycle

### Overview: From Submission to Completion

```
┌─────────────────────────────────────────────────────────────────┐
│                    COMPLETE REPORT FLOW                          │
└─────────────────────────────────────────────────────────────────┘

🧑 CITIZEN SUBMITS REPORT
    │
    ├─> Takes photo of drain
    ├─> Selects drain location
    ├─> Fills description, severity, traffic impact
    └─> Taps "Submit"
         │
         ↓
    ┌─────────────────────────────────────────────┐
    │   VALIDATION PIPELINE (7 STEPS)              │
    └─────────────────────────────────────────────┘
         │
         ├─> STEP 1: Resize & Watermark Image
         │   ├─ Resize to max 2048px
         │   └─ Add watermark (timestamp, GPS, logo)
         │
         ├─> STEP 2: Generate pHash
         │   └─ Perceptual hash for duplicate detection
         │
         ├─> STEP 3: Duplicate Check
         │   ├─ Query Firestore for matching hashes
         │   └─ IF DUPLICATE → ❌ REJECT
         │
         ├─> STEP 4: Upload to Cloudinary
         │   └─ Upload watermarked image → get URL
         │
         ├─> STEP 5: Location Intelligence
         │   ├─ Check if near school/hospital
         │   ├─ Calculate distances
         │   └─ Check rush hour (5-7 PM HCMC)
         │
         ├─> STEP 6: AI Validation (Gemini)
         │   ├─ Send image + context to AI
         │   ├─ Get validation response
         │   ├─ IF !isValid → ❌ REJECT
         │   └─ IF confidence < 0.7 → ❌ REJECT
         │
         └─> STEP 7: Risk Scoring
             ├─ Calculate 1.0-5.0 risk score
             └─ Determine if auto-assign needed
         │
         ↓
    ✅ VALIDATION SUCCESSFUL
         │
         └─> Save to Firebase
             ├─ Collection: /reports/{reportId}
             ├─ status: "Pending"              ✅ User sees "Pending"
             └─ workflowState: "Validated"     🔧 Internal: AI approved
         │
         ↓
    📱 USER SEES: "PENDING" (Orange)
```

---

## 🔄 Detailed Status Flow

### Phase 1: Submission & Validation

```
┌──────────────────────────────────────────────────────────┐
│  User Action: Submit Report                              │
└──────────────────────────────────────────────────────────┘
                         │
                         ↓
    ┌─────────────────────────────────────────┐
    │  Report Created                          │
    │  status: .pending                        │  ✅ User: "Pending"
    │  workflowState: "Sent"                   │  🔧 Internal: Just sent
    └─────────────────────────────────────────┘
                         │
                         ↓
    ┌─────────────────────────────────────────┐
    │  AI Validation Started                   │
    │  status: .pending (no change)            │  ✅ User: "Pending"
    │  workflowState: "Validating"             │  🔧 Internal: AI processing
    └─────────────────────────────────────────┘
                         │
                         ├──── ✅ AI Approves ────┐
                         │                         │
                         │                         ↓
                         │         ┌─────────────────────────────────────────┐
                         │         │  AI Validation Success                   │
                         │         │  status: .pending                        │  ✅ User: "Pending"
                         │         │  workflowState: "Validated"              │  🔧 Internal: AI approved
                         │         │  isValidated: true                       │
                         │         │  aiSeverity: 1-5                         │
                         │         │  aiConfidence: 0.7-1.0                   │
                         │         │  riskScore: 1.0-5.0                      │
                         │         └─────────────────────────────────────────┘
                         │                         │
                         │                         └──> 💾 Saved to Firebase
                         │
                         └──── ❌ AI Rejects ─────┐
                                                   │
                                                   ↓
                                    ┌─────────────────────────────────────────┐
                                    │  Rejected - NOT SAVED                    │
                                    │  User sees error message                 │
                                    │  Report not created in database          │
                                    └─────────────────────────────────────────┘
```

---

### Phase 2: Operator Assignment (Admin Action)

```
┌──────────────────────────────────────────────────────────┐
│  Admin/System: Assigns Operator                          │
└──────────────────────────────────────────────────────────┘
                         │
                         ↓
    ┌─────────────────────────────────────────┐
    │  Operator Assigned                       │
    │  status: .pending → .inProgress          │  ✅ User: "Pending" → "In Progress"
    │  workflowState: "Assigned"               │  🔧 Internal: Has operator
    │  assignedTo: "operator123"               │
    │  statusUpdatedAt: Date()                 │
    └─────────────────────────────────────────┘
                         │
                         └──> 💾 Updated in Firebase
                         └──> 📧 Operator notified
```

---

### Phase 3: Operator Works on Report

```
┌──────────────────────────────────────────────────────────┐
│  Operator Action: Start Work                             │
└──────────────────────────────────────────────────────────┘
                         │
                         ↓
    ┌─────────────────────────────────────────┐
    │  Work Started                            │
    │  status: .inProgress (no change)         │  ✅ User: "In Progress"
    │  workflowState: "In Progress"            │  🔧 Internal: Actually working
    │  statusUpdatedAt: Date()                 │
    └─────────────────────────────────────────┘
                         │
                         └──> 💾 Updated in Firebase
                         └──> 📱 User can see operator notes
```

---

### Phase 4: Completion

```
┌──────────────────────────────────────────────────────────┐
│  Operator Action: Mark as Complete                       │
└──────────────────────────────────────────────────────────┘
                         │
                         ↓
    ┌─────────────────────────────────────────┐
    │  Work Completed                          │
    │  status: .inProgress → .done             │  ✅ User: "In Progress" → "Done"
    │  workflowState: "Done"                   │  🔧 Internal: Completed
    │  completedAt: Date()                     │
    │  afterImageURL: "cloudinary.com/..."    │  📸 Before/after photo
    │  operatorNotes: "Fixed drain..."        │  📝 Completion notes
    └─────────────────────────────────────────┘
                         │
                         └──> 💾 Updated in Firebase
                         └──> 📧 User notified
                         └──> 🎉 Report closed
```

---

## 📊 Status Mapping Table

| Phase | User-Facing Status | WorkflowState | Firebase Saved? | What User Sees |
|-------|-------------------|---------------|-----------------|----------------|
| **Just submitted** | `.pending` | `"Sent"` | ❌ No (not yet validated) | Nothing (still submitting) |
| **AI processing** | `.pending` | `"Validating"` | ❌ No (validation in progress) | "Submitting..." |
| **AI approved** | `.pending` | `"Validated"` | ✅ **YES** | **"Pending"** (Orange) |
| **AI rejected** | N/A | `"Rejected"` | ❌ No | Error message, not saved |
| **Operator assigned** | `.inProgress` | `"Assigned"` | ✅ YES | **"In Progress"** (Purple) |
| **Operator working** | `.inProgress` | `"In Progress"` | ✅ YES | **"In Progress"** (Purple) |
| **Work completed** | `.done` | `"Done"` | ✅ YES | **"Done"** (Green) ✓ |

---

## 🗄️ Firebase Document Evolution

### 1️⃣ After AI Validation (First Save)

```json
{
  "id": "report_abc123",
  "userId": "user_xyz",
  "drainId": "drain_456",
  "drainTitle": "Drain near Nguyen Hue Street",
  
  "description": "Blocked drain with leaves",
  "userSeverity": "High",
  "trafficImpact": "Slowing",
  
  "timestamp": "2026-01-20T10:30:00Z",
  
  "imageURL": "https://res.cloudinary.com/...",
  "watermarkedImageURL": "https://res.cloudinary.com/...",
  "imageHash": "phash_abc123def456",
  
  "reporterLatitude": 10.7728,
  "reporterLongitude": 106.6986,
  "locationAccuracy": 8.5,
  
  // AI Validation Results
  "isValidated": true,
  "aiSeverity": 4,
  "aiConfidence": 0.85,
  "aiProcessedAt": "2026-01-20T10:30:15Z",
  "detectedIssue": "Severe blockage detected",
  "validationReasons": ["Clear drain visible", "Blockage confirmed"],
  
  // Location Intelligence
  "nearSchool": true,
  "distanceToSchool": 150.0,
  "nearHospital": false,
  "distanceToHospital": 800.0,
  "submittedDuringRushHour": false,
  "nearbyPOIs": ["School", "Shopping Mall"],
  
  // Risk Assessment
  "riskScore": 4.2,
  
  // ✅ STATUS - What user sees
  "status": "Pending",
  
  // 🔧 WORKFLOW - Internal tracking
  "workflowState": "Validated",
  
  // Workflow fields (empty initially)
  "assignedTo": null,
  "statusUpdatedAt": "2026-01-20T10:30:15Z",
  "operatorNotes": null,
  "afterImageURL": null,
  "completedAt": null
}
```

### 2️⃣ After Operator Assignment

```json
{
  // ... all previous fields ...
  
  // ✅ STATUS CHANGED
  "status": "In Progress",
  
  // 🔧 WORKFLOW CHANGED
  "workflowState": "Assigned",
  
  // NEW FIELDS
  "assignedTo": "operator_john_123",
  "statusUpdatedAt": "2026-01-20T11:00:00Z"
}
```

### 3️⃣ After Operator Starts Work

```json
{
  // ... all previous fields ...
  
  // ✅ STATUS (no change)
  "status": "In Progress",
  
  // 🔧 WORKFLOW CHANGED
  "workflowState": "In Progress",
  
  "statusUpdatedAt": "2026-01-20T11:15:00Z",
  "operatorNotes": "On my way to location"
}
```

### 4️⃣ After Completion

```json
{
  // ... all previous fields ...
  
  // ✅ STATUS CHANGED
  "status": "Done",
  
  // 🔧 WORKFLOW CHANGED
  "workflowState": "Done",
  
  "statusUpdatedAt": "2026-01-20T14:30:00Z",
  "operatorNotes": "Drain cleaned. Removed leaves and debris. All clear now.",
  "afterImageURL": "https://res.cloudinary.com/after_photo.jpg",
  "completedAt": "2026-01-20T14:30:00Z"
}
```

---

## 📱 What Users See at Each Stage

### Stage 1: Submitting Report
```
┌─────────────────────────────────┐
│  Submitting Report...           │
│  ⏳ AI validating your photo    │
│  [Progress bar: 85%]            │
└─────────────────────────────────┘
```

### Stage 2: After AI Validation (Saved as Pending)
```
┌─────────────────────────────────┐
│  ✅ Report Submitted!            │
│  Your report is now pending     │
│  review by operators.           │
│                                 │
│  Status: 🟠 Pending             │
└─────────────────────────────────┘

In StatusView "Pending" tab:
┌─────────────────────────────────┐
│  Drain near Nguyen Hue Street   │
│  📅 Jan 20, 2026                │
│  🟠 Pending                     │
│  ⚠️ Risk: 4.2/5.0               │
└─────────────────────────────────┘
```

### Stage 3: After Operator Assignment (Changed to In Progress)
```
In StatusView "In Progress" tab:
┌─────────────────────────────────┐
│  Drain near Nguyen Hue Street   │
│  📅 Jan 20, 2026                │
│  🟣 In Progress                 │
│  👷 Assigned to: John Nguyen    │
│  ⚠️ Risk: 4.2/5.0               │
└─────────────────────────────────┘
```

### Stage 4: After Completion (Changed to Done)
```
In StatusView "Done" tab:
┌─────────────────────────────────┐
│  Drain near Nguyen Hue Street   │
│  📅 Jan 20, 2026                │
│  ✅ Done                        │
│  ✓ Completed: Jan 20, 2:30 PM  │
│  📸 [Before/After Photos]       │
│  📝 Notes: Drain cleaned...     │
└─────────────────────────────────┘
```

---

## 🔧 Developer Console Logs

### During Submission:

```
🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀
🚀 [VALIDATION] STARTING REPORT VALIDATION PIPELINE
🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀

━━━ STEP 1/7: PREPARING & WATERMARKING IMAGE ━━━
📐 [RESIZE] Image resized from 3024x4032 to 1536x2048
📊 [SIZE] Watermarked image size: 1250KB

━━━ STEP 2/7: GENERATING PHASH ━━━
🔍 [PHASH] Generated: phash_abc123def456

━━━ STEP 3/7: CHECKING DUPLICATES ━━━
🔍 [DUPLICATE] Checking for duplicate pHash
✅ [DUPLICATE] No duplicates found

━━━ STEP 4/7: UPLOADING IMAGE ━━━
☁️ [CLOUDINARY] Uploading watermarked image...
✅ [CLOUDINARY] Upload complete: https://res.cloudinary.com/...

━━━ STEP 5/7: LOCATION INTELLIGENCE ━━━
📍 [LOCATION] Analyzing location...
🏫 [LOCATION] Near school: YES (150m)
🏥 [LOCATION] Near hospital: NO (800m)
🕐 [LOCATION] Rush hour: NO
✅ [LOCATION] Analysis complete

━━━ STEP 6/7: AI VALIDATION ━━━
🤖 [AI] Starting AI validation
🤖 [AI] Sending to Gemini API...
🤖 [AI] Response received
✅ [AI] Validation: VALID
✅ [AI] Confidence: 85%
✅ [AI] Severity: 4/5

━━━ STEP 7/7: RISK SCORING ━━━
📊 [RISK] Calculating risk score...
📊 [RISK] AI Severity: 4
📊 [RISK] User Severity: High
📊 [RISK] Traffic Impact: Slowing
📊 [RISK] Near School: +0.5
✅ [RISK] Final Score: 4.2/5.0

━━━ SAVING TO FIREBASE ━━━
💾 [FIREBASE] Saving validated report...
📋 [STATUS] Setting status: Pending
🔧 [WORKFLOW] Setting workflowState: Validated
✅ [FIREBASE] Report saved with ID: report_abc123
💾 [FIREBASE] Saving pHash...
✅ [FIREBASE] pHash saved

✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅
✅ [VALIDATION] VALIDATION SUCCESSFUL!
✅ Report ID: report_abc123
✅ Risk Score: 4.2/5.0
✅ AI Confidence: 85%
✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅
```

---

## 🎯 Key Takeaways

### Status Assignment Rules:

1. **After AI Validation** (Report First Saved to Firebase):
   ```swift
   status = .pending           // ✅ User sees "Pending"
   workflowState = "Validated" // 🔧 Internal: AI approved
   ```

2. **After Operator Assignment**:
   ```swift
   status = .inProgress        // ✅ User sees "In Progress"
   workflowState = "Assigned"  // 🔧 Internal: Has operator
   ```

3. **After Work Completion**:
   ```swift
   status = .done              // ✅ User sees "Done"
   workflowState = "Done"      // 🔧 Internal: Completed
   ```

### Important Notes:

- ✅ **Only validated reports are saved** - Rejected reports never reach Firebase
- 🟠 **All saved reports start as "Pending"** - Waiting for operator assignment
- 🟣 **"In Progress" means operator is involved** - Either assigned or actively working
- 🟢 **"Done" is final state** - Work completed, report closed
- 🔧 **workflowState provides detail** - For logging and internal tracking
- 📱 **Users only see 3 statuses** - Simple and clear

---

## 🔄 Workflow State Transitions

```
Initial State → Validating → Validated → Assigned → In Progress → Done
     ↓              ↓           ↓           ↓            ↓          ↓
  (no save)     (no save)  [PENDING]  [IN PROGRESS] [IN PROGRESS] [DONE]
                              🟠          🟣            🟣          🟢
```

**Legend:**
- `()` = Not saved to database
- `[]` = User-facing status in database
- 🟠 Orange = Pending
- 🟣 Purple = In Progress
- 🟢 Green = Done

---

**Last Updated:** January 20, 2026  
**Status System Version:** 2.0
