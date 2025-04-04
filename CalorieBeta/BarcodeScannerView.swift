import SwiftUI
<<<<<<< HEAD
import FirebaseFirestore
import AVFoundation

struct BarcodeScannerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var onFoodItemDetected: (FoodItem) -> Void

    private let fatSecretService = FatSecretFoodAPIService()
=======
import AVFoundation

struct BarcodeScannerView: UIViewControllerRepresentable {
    var didFindBarcode: (String) -> Void
>>>>>>> d3d7eb3 (Initial commit)

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

<<<<<<< HEAD
    func makeUIViewController(context: Context) -> ScannerViewController {
        let viewController = ScannerViewController()
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
=======
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return viewController }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
        } catch {
            return viewController
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .qr]
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = viewController.view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        viewController.view.layer.addSublayer(previewLayer)

        captureSession.startRunning()

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
>>>>>>> d3d7eb3 (Initial commit)

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: BarcodeScannerView

        init(parent: BarcodeScannerView) {
            self.parent = parent
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first,
               let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
               let barcode = readableObject.stringValue {
<<<<<<< HEAD

                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.parent.presentationMode.wrappedValue.dismiss()
                    self.fetchFromFatSecret(barcode: barcode)
                }
            }
        }

        private func fetchFromFatSecret(barcode: String) {
            parent.fatSecretService.fetchFoodByBarcode(barcode: barcode) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let foodItems):
                        if let firstFoodItem = foodItems.first {
                            print("✅ Navigating to FoodDetailView for: \(firstFoodItem.name)")
                            
                            // ✅ Pass full food item to handler
                            self.parent.onFoodItemDetected(firstFoodItem)
                        } else {
                            print("⚠️ No valid results found.")
                        }
                    case .failure(let error):
                        print("❌ No results found. Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

// ✅ **Restored `ScannerViewController` to fix "Cannot find in scope" errors**
class ScannerViewController: UIViewController {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer!
    var delegate: AVCaptureMetadataOutputObjectsDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupOverlay()
    }

    func setupCamera() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession?.canAddInput(videoInput) == true {
                captureSession?.addInput(videoInput)
            }
        } catch {
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession?.canAddOutput(metadataOutput) == true {
            captureSession?.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .qr]
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .background).async {
            self.captureSession?.startRunning() // ✅ **Moved to background to prevent UI freeze**
        }
    }

    func setupOverlay() {
        let overlayView = UIView()
        overlayView.layer.borderColor = UIColor.green.cgColor
        overlayView.layer.borderWidth = 3
        overlayView.backgroundColor = UIColor.clear
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)

        NSLayoutConstraint.activate([
            overlayView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            overlayView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            overlayView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            overlayView.heightAnchor.constraint(equalTo: overlayView.widthAnchor, multiplier: 0.5)
        ])
=======
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                parent.handleBarcode(barcode)
            }
        }
    }

    // Handle the scanned barcode and query the OpenFoodFacts API
    private func handleBarcode(_ barcode: String) {
        let endpoint = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"

        guard let url = URL(string: endpoint) else {
            print("Invalid URL for barcode \(barcode)")
            didFindBarcode("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.didFindBarcode("Error fetching data")
                }
                return
            }

            guard let data = data else {
                print("No data returned from API")
                DispatchQueue.main.async {
                    self.didFindBarcode("No data")
                }
                return
            }

            do {
                // Decode the API response
                let apiResponse = try JSONDecoder().decode(OpenFoodFactsAPIResponse.self, from: data)

                // Check if product data is available
                if let product = apiResponse.product {
                    DispatchQueue.main.async {
                        self.didFindBarcode(product.productName ?? "Unknown Product")
                    }
                } else {
                    print("No product found for barcode \(barcode)")
                    DispatchQueue.main.async {
                        self.didFindBarcode("No product found")
                    }
                }
            } catch {
                print("Error decoding API response: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.didFindBarcode("Error decoding data")
                }
            }
        }.resume()
    }
}

// MARK: - API Response Structs

// The main response structure from OpenFoodFacts API
struct OpenFoodFactsAPIResponse: Decodable {
    let code: String?
    let product: OpenFoodFactsProduct?
    let status: Int?
    let statusVerbose: String?

    enum CodingKeys: String, CodingKey {
        case code
        case product
        case status
        case statusVerbose = "status_verbose"
    }
}

// The product information structure within the response
struct OpenFoodFactsProduct: Decodable {
    let productName: String?
    let nutriments: OpenFoodFactsNutrients?
    let servingSize: String?
    let servingWeight: Double?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case nutriments
        case servingSize = "serving_size"
        case servingWeight = "serving_weight"
    }
}

// The nutrients structure within the product information
struct OpenFoodFactsNutrients: Decodable {
    let energyKcal: Double?
    let proteins: Double?
    let carbohydrates: Double?
    let fat: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal = "energy-kcal_100g"
        case proteins = "proteins_100g"
        case carbohydrates = "carbohydrates_100g"
        case fat = "fat_100g"
>>>>>>> d3d7eb3 (Initial commit)
    }
}
