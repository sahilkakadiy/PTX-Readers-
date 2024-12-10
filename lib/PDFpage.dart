import 'dart:async';
import 'dart:io';
import 'package:docx_file_viewer/docx_file_viewer.dart';
import 'package:epub_view/epub_view.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:pdfx/pdfx.dart'; // For PDFs
import 'package:docx_to_text/docx_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';

class MHomePage extends StatefulWidget {
  @override
  _MHomePageState createState() => _MHomePageState();
}

class _MHomePageState extends State<MHomePage> with TickerProviderStateMixin{
  late TabController _tabController;
  List<PlatformFile> selectedFiles = [];
  Map<String, List<List<dynamic>>> excelData = {};  // To store Excel data for each file

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _tabController = TabController(length: 4, vsync: this);  // 2 tabs: One for file selection and another for previewing
  }



  void _requestPermissions() async {
    if (!kIsWeb) {
      // Request permissions for non-web platforms (Android, iOS, etc.)
      PermissionStatus status = await Permission.storage.request();
      if (status.isGranted) {
        print('Storage permission granted');
      } else {
        print('Storage permission denied');
      }
    } else {
      // Handle permission request differently for the web
      print('Permissions are not supported on the web.');
    }
  }

  // Function to pick files
  Future<void> pickFiles() async {
    if (await Permission.manageExternalStorage.isGranted) {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true, // Allow picking multiple files
      type: FileType.custom, // To allow specific file types
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'epub', 'txt', 'xlsx'],
    );

    if (result != null) {
      setState(() {
        selectedFiles = result.files;
      });
    } } else {
      // Request manage storage permission for Android 10+
      await Permission.manageExternalStorage.request();
    }
  }

  // Function to navigate to the file read page
  void viewFile(BuildContext context, PlatformFile file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FileReadPage(filePath: file),
      ),
    );
  }


  List<PlatformFile> getFilteredFiles(String extension) {
    return selectedFiles.where((file) => file.extension == extension).toList();
  }


  Future<void> readExcelFile(PlatformFile file) async {
    final bytes = File(file.path!).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    if (excel != null) {
      var sheet = excel.tables.values.first;
      List<List<dynamic>> rows = [];
      for (var row in sheet.rows) {
        rows.add(row);
      }

      // Store the Excel data for the specific file
      setState(() {
        excelData[file.name ?? 'unknown'] = rows;
      });
    }
  }

  IconData getFileIcon(String? extension) {
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'epub':
        return Icons.library_books;
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file; // Default file icon
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.teal.shade300,
        title: Text('All Files',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,letterSpacing: 1),),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(60.0),  // Set the preferred height of the TabBar
            child: Container(
              width: double.infinity,  // Ensure the container takes up full width
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.grey,  // White indicator color
                indicatorSize: TabBarIndicatorSize.label,  // Indicator size based on label
                onTap: (index) {
                  setState(() {
                    // Ensure the color and indicator are updated on tab change
                  });
                },
                tabs: [
                  // PDF Tab with Red color and rounded shape
                  Tab(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0), // Reduce padding to prevent overflow
                      decoration: BoxDecoration(
                        color: _tabController.index == 0 ? Colors.red : Colors.transparent,
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            color: _tabController.index == 0 ? Colors.white : Colors.black,
                          ),
                          SizedBox(width: 8),
                          Expanded(  // Ensure that text takes up available space
                            child: Text(
                              'PDF',
                              style: TextStyle(
                                color: _tabController.index == 0 ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,  // Add ellipsis in case text overflows
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // EPUB Tab with Green color and rounded shape
                  Tab(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 6.0,horizontal: 8),
                      decoration: BoxDecoration(
                        color: _tabController.index == 1 ? Colors.green : Colors.transparent,  // Green background for active tab
                        borderRadius: BorderRadius.circular(30.0),  // Round the corners
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.library_books,
                            color: _tabController.index == 1 ? Colors.white : Colors.black,  // White icon for active tab
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Epub',
                            style: TextStyle(
                              color: _tabController.index == 1 ? Colors.white : Colors.black,  // White text for active tab
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // DOCX Tab with Blue color and rounded shape
                  Tab(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 6.0,horizontal: 8),
                      decoration: BoxDecoration(
                        color: _tabController.index == 2 ? Colors.blue : Colors.transparent,  // Blue background for active tab
                        borderRadius: BorderRadius.circular(30.0),  // Round the corners
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description,
                            color: _tabController.index == 2 ? Colors.white : Colors.black,  // White icon for active tab
                          ),
                          SizedBox(width: 8),
                          Text(
                            'DocX',
                            style: TextStyle(
                              color: _tabController.index == 2 ? Colors.white : Colors.black,  // White text for active tab
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Tab(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 8),
                      decoration: BoxDecoration(
                        color: _tabController.index == 3 ? Colors.orange : Colors.transparent,  // Orange background for active tab
                        borderRadius: BorderRadius.circular(30.0),  // Round the corners
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.table_chart,
                            color: _tabController.index == 3 ? Colors.white : Colors.black,  // White icon for active tab
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Excel',
                            style: TextStyle(
                              color: _tabController.index == 3 ? Colors.white : Colors.black,  // White text for active tab
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                ],
              ),
            ),
          )
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: PDF Files
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                selectedFiles.isEmpty
                    ? Center(child: Text('No PDF files selected'))
                    : Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: getFilteredFiles('pdf').length,  // Only show PDF files
                    itemBuilder: (context, index) {
                      PlatformFile file = getFilteredFiles('pdf')[index];
                      return GestureDetector(
                        onTap: () => viewFile(context, file),
                        child: Padding(
                          padding: const EdgeInsets.all(1),
                          child: Card(
                            elevation: 4.0,
                            child:Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Icon(
                                    getFileIcon(file.extension),
                                    size: 30,
                                    color: Colors.redAccent,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(  // Added Expanded to ensure the text has enough space
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,  // Aligns the text to the start (left)
                                      children: [
                                        Text(
                                          file.name,
                                          overflow: TextOverflow.ellipsis,  // Proper handling of long text
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 4),  // Added space between file name and extension
                                        Text(
                                          file.extension ?? 'Unknown',  // Safely display file extension
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Tab 2: Epub Files
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                selectedFiles.isEmpty
                    ? Center(child: Text('No Epub files selected'))
                    : Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: getFilteredFiles('epub').length,  // Only show EPUB files
                    itemBuilder: (context, index) {
                      PlatformFile file = getFilteredFiles('epub')[index];
                      return GestureDetector(
                        onTap: () => viewFile(context, file),
                        child: Padding(
                          padding: const EdgeInsets.all(1),
                          child: Card(
                            elevation: 4.0,
                            child:Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Icon(
                                    getFileIcon(file.extension),
                                    size: 30,
                                    color: Colors.greenAccent.shade700,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(  // Added Expanded to ensure the text has enough space
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,  // Aligns the text to the start (left)
                                      children: [
                                        Text(
                                          file.name,
                                          overflow: TextOverflow.ellipsis,  // Proper handling of long text
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 4),  // Added space between file name and extension
                                        Text(
                                          file.extension ?? 'Unknown',  // Safely display file extension
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Tab 3: DOCX Files
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                selectedFiles.isEmpty
                    ? Center(child: Text('No DocX files selected'))
                    : Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: getFilteredFiles('docx').length,  // Only show DOCX files
                    itemBuilder: (context, index) {
                      PlatformFile file = getFilteredFiles('docx')[index];
                      return GestureDetector(
                        onTap: () => viewFile(context, file),
                        child: Padding(
                          padding: const EdgeInsets.all(1),
                          child: Card(
                            elevation: 4.0,
                            child:Padding(
                              padding: const EdgeInsets.all(8.0),
                              child:Row(
                                children: [
                                  Icon(
                                    getFileIcon(file.extension),
                                    size: 30,
                                    color: Colors.blueAccent,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(  // Added Expanded to ensure the text has enough space
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,  // Aligns the text to the start (left)
                                      children: [
                                        Text(
                                          file.name,
                                          overflow: TextOverflow.ellipsis,  // Proper handling of long text
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 4),  // Added space between file name and extension
                                        Text(
                                          file.extension ?? 'Unknown',  // Safely display file extension
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                selectedFiles.isEmpty
                    ? Center(child: Text('No Excel files selected'))
                    : Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: getFilteredFiles('xlsx').length,
                    itemBuilder: (context, index) {
                      PlatformFile file = getFilteredFiles('xlsx')[index];
                      return GestureDetector(
                        onTap: () => viewFile(context, file),
                        child: Padding(
                          padding: const EdgeInsets.all(1),
                          child: Card(
                            elevation: 4.0,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.table_chart,
                                    size: 30,
                                    color: Colors.blueAccent,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          file.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          file.extension ?? 'Unknown',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: pickFiles,child: Icon(Icons.add_link_sharp),tooltip: 'Add File', ),
    );
  }
}

class FileReadPage extends StatefulWidget {
  final PlatformFile filePath;

  FileReadPage({required this.filePath});

  @override
  _FileReadPageState createState() => _FileReadPageState();
}

class _FileReadPageState extends State<FileReadPage> {
  late PdfController _pdfController;  // Declare as late
  EpubController? _epubController; // EPUB controller for epub_view
  bool isPdfLoaded = false;
  late Uint8List pdfBytes;
  late Uint8List epubBytes;
  late Uint8List xlsxBytes;

  @override
  void initState() {
    super.initState();

    // Check for PDF file type and initialize the controller for PDF
    if (widget.filePath.extension == 'pdf') {
      if (kIsWeb) {
        // For Web, load the PDF from bytes directly
        pdfBytes = widget.filePath.bytes!;
        _pdfController = PdfController(
          document: PdfDocument.openData(pdfBytes),
        );
      } else {
        // For Mobile, use path
        _loadPdfFile(File(widget.filePath.path!));
      }
    }

    if (widget.filePath.extension == 'epub') {
      if (kIsWeb) {
        // For Web, load the PDF from bytes directly
        epubBytes = widget.filePath.bytes!;
        _epubController = EpubController(
          document: EpubDocument.openData(epubBytes),
        );
      } else {
        // For Mobile, use path
        _loadepubFile(File(widget.filePath.path!));
      }
    }

    if (widget.filePath.extension == 'xlsx') {
      _loadExcelFile(widget.filePath);  // Load Excel file
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _epubController?.dispose();
    _pdfController.dispose();
    super.dispose();
  }
  // Load PDF from File for non-web platforms (Android, iOS)
  void _loadPdfFile(File file) async {
    try {
      final fileBytes = await file.readAsBytes();
      if (fileBytes.isNotEmpty) {
        setState(() {
          pdfBytes = fileBytes;
          isPdfLoaded = true;
        });
        _pdfController = PdfController(
          document: PdfDocument.openData(fileBytes),
        );
        print("PDF file loaded successfully.");
      } else {
        print("Error: PDF file bytes are empty.");
      }
    } catch (e) {
      print("Error loading PDF: $e");
    }
  }
  void _loadepubFile(File file) async {
    try {
      final fileBytes = await file.readAsBytes();
      if (fileBytes.isNotEmpty) {
        setState(() {
          epubBytes = fileBytes;
          isPdfLoaded = true;
        });
        _epubController = EpubController(
          document: EpubDocument.openData(fileBytes),
        );
        print("Epub file loaded successfully.");
      } else {
        print("Error: Epub file bytes are empty.");
      }
    } catch (e) {
      print("Error loading Epub: $e");
    }
  }
  void _loadExcelFile(PlatformFile file) async {
    try {
      final fileBytes = file.bytes!;
      if (fileBytes.isNotEmpty) {
        setState(() {
          xlsxBytes = fileBytes;
        });
        _parseExcelFile(fileBytes);
      } else {
        print("Error: Excel file bytes are empty.");
      }
    } catch (e) {
      print("Error loading Excel: $e");
    }
  }
  void _parseExcelFile(Uint8List bytes) async {
    try {
      var excel = Excel.decodeBytes(bytes);
      // Example: Extract the first sheet's first row
      var sheet = excel?.tables.values.first;
      var rows = sheet?.rows;
      print("Excel sheet rows: $rows");

      // For now, just display the first row's data as a preview (you can customize this)
      setState(() {
        // You could add logic here to display the data more elegantly
      });
    } catch (e) {
      print("Error parsing Excel file: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade300,
        title: Text('${widget.filePath.name}',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,letterSpacing: 1)), // Displaying file name from the path
        actions: [
          // PDF info button to show file information
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) => _fileInfoDialog(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _getFilePreview(widget.filePath)),
        ],
      ),
    );
  }

  Widget _getFilePreview(PlatformFile file) {
    switch (file.extension) {
      case 'pdf':
        return _showPdfPreview();
      case 'epub':
        return _showEpubPreview();
      case 'docx':
        return _showDocxPreview(file);
      case 'xlsx':
        return _showExcelPreview();
      default:
        return Center(child: Text('No preview available for this file type.'));
    }
  }
  Widget _showPdfPreview() {
    if (kIsWeb) {
      // For Web, display PDF using PdfController created with bytes
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: PdfView(
          controller: _pdfController,
          scrollDirection: Axis.vertical,
        ),
      );
    } else {
      // For Mobile (Android, iOS), use path
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: PDFView(
          pageSnap: true,
          pageFling: true,
          autoSpacing: true,
          fitEachPage: true,
          filePath: widget.filePath.path!,  // Use path for mobile
          onPageChanged: (page, total) {
            print("Page changed: $page / $total");
          },
          onError: (error) {
            print("Error: $error");
          },
          onViewCreated: (PDFViewController pdfViewController) {
            print("PDFView created.");
          },
        ),
      );
    }
  }
  // Handle EPUB preview
  Widget _showEpubPreview() {
    if (kIsWeb) {
      // For Web, load EPUB from bytes
      return FutureBuilder(
        future: _loadEpubFromFile(widget.filePath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return EpubView(controller: snapshot.data as EpubController);
            } else {
              return Center(child: Text("Failed to load EPUB"));
            }
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      );
    } else {
      // For Mobile platforms, use the file path
      return EpubView(
        controller: _epubController!,
        shrinkWrap: true,
      );
    }
  }

  // Load EPUB from file for web
  Future<EpubController> _loadEpubFromFile(PlatformFile file) async {
     return EpubController(document: EpubDocument.openData(file.bytes!));
  }
  Widget _showDocxPreview(PlatformFile file) {
    if (kIsWeb) {
      // Handle web case separately (no Platform API available)
      return Container(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 10),
              _renderDocxContent(file.bytes!), // Assuming `bytes` is available
            ],
          ),
        ),
      );
    }

    // Check for non-web platforms (Android, iOS, Windows, macOS, Linux)
    if (Platform.isAndroid || Platform.isIOS || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 8,right: 8),
          child: DocxViewer(file: File(file.path!)),
        ), // Use `file.path!` here
      );
    } else {
      return Center(child: Text('Unsupported platform.'));
    }
  }


  Widget _renderDocxContent(Uint8List fileBytes) {
    // Parse the DOCX file bytes and display its content
    try {
      final content = docxToText(fileBytes); // Placeholder logic
      // Replace with actual DOCX parsing logic
      return Container(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            content.toString(),
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.left,
          ),
        ),
      );
    } catch (e) {
      return Text("Failed to render DOCX content: $e");
    }
  }

  Widget _showExcelPreview() {
    if (xlsxBytes.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    // Display the first few rows of the Excel file as text (or customize as needed)
    return ListView.builder(
      itemCount: 5,  // Show first 5 rows, for example
      itemBuilder: (context, index) {
        return ListTile(
          title: Text("Row $index: ${xlsxBytes.toString()}"),  // Example, replace with actual data
        );
      },
    );
  }

  // File info dialog
  Widget _fileInfoDialog() {
    return AlertDialog(
      title: Text("File Info"),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('File Name: ${widget.filePath.name}', style: TextStyle(fontSize: 18)),
          Text('Extension: ${widget.filePath.extension ?? "Unknown"}', style: TextStyle(fontSize: 16)),
          Text('File Size: ${widget.filePath.size} bytes', style: TextStyle(fontSize: 16)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Close'),
        ),
      ],
    );
  }
}



