# Bug Fix: Report ID không hiển thị và Detail View không hoạt động

## 🐛 Vấn đề

1. **Report ID hiển thị "#Unknown"** thay vì ID thực tế
2. **Khi click vào report không hiện inner details** 

## 🔍 Nguyên nhân

Khi fetch reports từ Firestore sử dụng `doc.data(as: Report.self)`, property `@DocumentID var id: String?` không tự động được populate với document ID từ Firestore.

Điều này xảy ra vì:
- `@DocumentID` property wrapper cần đặc biệt xử lý từ Firestore decoder
- Trong một số trường hợp, decoder không tự động map document ID vào property được đánh dấu `@DocumentID`
- Code cũ sử dụng `try? doc.data(as: Report.self)` mà không kiểm tra hoặc gán ID manually

## ✅ Giải pháp đã áp dụng

### 1. Sửa `ReportService.swift` - Hàm `fetchUserReports`

**Trước:**
```swift
let reports = snapshot.documents.compactMap { doc -> Report? in
    try? doc.data(as: Report.self)
}
```

**Sau:**
```swift
let reports = snapshot.documents.compactMap { doc -> Report? in
    do {
        var report = try doc.data(as: Report.self)
        // Manually set the document ID if it wasn't populated
        if report.id == nil {
            report.id = doc.documentID
            print("📝 Set report ID: \(doc.documentID)")
        }
        return report
    } catch {
        print("⚠️ Failed to decode report document \(doc.documentID): \(error.localizedDescription)")
        return nil
    }
}
```

**Cải tiến:**
- Kiểm tra nếu `report.id` là `nil` sau khi decode
- Manually set `id = doc.documentID` từ Firestore
- Thêm proper error handling thay vì silent fail với `try?`
- Thêm logging để debug

### 2. Thêm Debug Logging vào `StatusViewModel`

Thêm logging để track report IDs khi fetch:

```swift
print("✅ [StatusView] Loaded \(fetchedReports.count) reports")

// Debug: Print all report IDs
for (index, report) in fetchedReports.enumerated() {
    print("   Report \(index + 1): ID = \(report.id ?? "nil"), Title = \(report.drainTitle)")
}
```

### 3. Thêm Logging khi tap vào Report

```swift
Button {
    print("📱 [StatusView] Tapped report ID: \(report.id ?? "nil")")
    selectedReport = report
    showDetail = true
} label: {
    StatusCardView(...)
}
```

## 🧪 Test Cases

Sau khi fix, kiểm tra:

1. ✅ Report ID hiển thị đúng document ID từ Firestore (ví dụ: `#abc123`)
2. ✅ Khi tap vào report, `ReportDetailView` hiển thị đầy đủ thông tin
3. ✅ Console logs cho thấy ID được set đúng
4. ✅ Tất cả reports đều có ID hợp lệ

## 📊 Expected Console Output

```
📥 [StatusView] Fetching reports for user: abc123xyz
📥 Fetching reports for user: abc123xyz
📝 Set report ID: KXmh8Pq9vLn4Rw2T
📝 Set report ID: JHg7Oo5Mk3Ln1Qw9
✅ Fetched 2 reports
📋 First report ID: KXmh8Pq9vLn4Rw2T
📋 First report title: Crescent Mall Area
✅ [StatusView] Loaded 2 reports
   Report 1: ID = KXmh8Pq9vLn4Rw2T, Title = Crescent Mall Area
   Report 2: ID = JHg7Oo5Mk3Ln1Qw9, Title = District 1 Main Street
```

## 🔧 Files Modified

1. **ReportService.swift** - Fixed `fetchUserReports()` method
2. **StatusView.swift** - Added debug logging

## 📝 Notes

- `@DocumentID` property wrapper đôi khi không hoạt động tự động với Firestore decoder
- Best practice: Luôn kiểm tra và manually set document ID sau khi decode
- Sử dụng proper error handling (`do-catch`) thay vì silent fail (`try?`) để dễ debug

## 🚀 Next Steps

Nếu vẫn gặp vấn đề:

1. Kiểm tra Firestore console xem documents có tồn tại không
2. Xem console logs để xác nhận IDs được set
3. Verify Firebase Auth user ID đúng với userId trong reports
4. Kiểm tra Firestore security rules cho phép read

---
## 🐛 Update: Detail View không hiển thị

### Vấn đề tiếp theo
Report IDs đã fetch đúng nhưng khi tap vào report, DetailView không hiển thị gì.

### Debug Steps

**1. Thêm logging vào StatusView presentation:**
```swift
.sheet(isPresented: $showDetail) {
    if let report = selectedReport {
        print("📱 [StatusView] Presenting detail for report: \(report.id ?? "nil")")
        ReportDetailView(report: report)
    } else {
        print("⚠️ [StatusView] selectedReport is nil!")
        // Fallback error view
    }
}
```

**2. Thêm logging vào ReportDetailView init:**
```swift
init(report: Report) {
    print("📋 [ReportDetail] Initializing with report ID: \(report.id ?? "nil")")
    print("📋 [ReportDetail] Report title: \(report.drainTitle)")
    print("📋 [ReportDetail] Report status: \(report.status.rawValue)")
    // ... rest of init
}
```

**3. Đổi background color để test:**
- Thay `Color("main")` → `Color(.systemBackground)` 
- Có thể custom color "main" không tồn tại trong Assets

**4. Tạo simplified test view:**
```swift
var body: some View {
    ZStack {
        Color(.systemBackground).ignoresSafeArea()
        
        VStack {
            Text("🎉 DETAIL VIEW LOADED!")
                .font(.largeTitle)
            
            Text("Report ID: \(report.id ?? "Unknown")")
            Text("Title: \(report.drainTitle)")
            
            Button("Close") {
                dismiss()
            }
        }
    }
}
```

### Possible Causes

1. **Custom color missing**: `Color("main")` không có trong Assets
2. **Font missing**: `BubblerOne-Regular` font chưa được import
3. **Layout issue**: ScrollView hoặc VStack bị hide bởi background
4. **Sheet vs FullScreenCover**: Thử đổi `.fullScreenCover` → `.sheet` để test

### Expected Console Output (Debug)

```
📱 [StatusView] Tapped report ID: vpellRKBnZEuwcL0hEVE
📱 [StatusView] Presenting detail for report: vpellRKBnZEuwcL0hEVE
📋 [ReportDetail] Initializing with report ID: vpellRKBnZEuwcL0hEVE
📋 [ReportDetail] Report title: Crescent Mall Area
📋 [ReportDetail] Report status: Pending
```

Nếu thấy log "Presenting detail" nhưng không thấy "Initializing", thì view chưa được tạo → vấn đề ở presentation modifier.

Nếu thấy "Initializing" nhưng màn hình trống → vấn đề ở layout/rendering.


