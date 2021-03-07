import 'dart:io';
import 'dart:typed_data';
import 'package:at_contact/at_contact.dart';
import 'package:at_contacts_group_flutter/at_contacts_group_flutter.dart';
import 'package:atsign_atmosphere_pro/data_models/file_modal.dart';
import 'package:atsign_atmosphere_pro/data_models/file_transfer_status.dart';
import 'package:atsign_atmosphere_pro/routes/route_names.dart';
import 'package:atsign_atmosphere_pro/services/backend_service.dart';
import 'package:atsign_atmosphere_pro/services/navigation_service.dart';
import 'package:atsign_atmosphere_pro/view_models/base_model.dart';
import 'package:atsign_atmosphere_pro/view_models/history_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:path/path.dart' show basename;

class FileTransferProvider extends BaseModel {
  FileTransferProvider._();
  static FileTransferProvider _instance = FileTransferProvider._();
  factory FileTransferProvider() => _instance;
  final String MEDIA = 'MEDIA';
  final String FILES = 'FILES';
  static List<PlatformFile> appClosedSharedFiles = [];
  String PICK_FILES = 'pick_files';
  String VIDEO_THUMBNAIL = 'video_thumbnail';
  String ACCEPT_FILES = 'accept_files';
  String SEND_FILES = 'send_files';
  List<SharedMediaFile> _sharedFiles;
  FilePickerResult result;
  PlatformFile file;

  List<PlatformFile> selectedFiles = [];
  List<FileTransferStatus> transferStatus = [];
  Map<String, List<Map<String, bool>>> transferStatusMap = {};
  bool sentStatus = false;
  Uint8List videoThumbnail;
  double totalSize = 0;

  BackendService _backendService = BackendService.getInstance();
  List<AtContact> temporaryContactList = [];

  setFiles() async {
    setStatus(PICK_FILES, Status.Loading);
    try {
      selectedFiles = [];
      totalSize = 0;
      if (appClosedSharedFiles.isNotEmpty) {
        appClosedSharedFiles.forEach((element) {
          selectedFiles.add(element);
        });
        calculateSize();
      }
      appClosedSharedFiles = [];
      setStatus(PICK_FILES, Status.Done);
    } catch (error) {
      setError(PICK_FILES, error.toString());
    }
  }

  pickFiles(String choice) async {
    setStatus(PICK_FILES, Status.Loading);
    try {
      List<PlatformFile> tempList = [];
      if (selectedFiles.isNotEmpty) {
        tempList = selectedFiles;
      }
      selectedFiles = [];

      totalSize = 0;

      result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: choice == MEDIA ? FileType.media : FileType.any,
          allowCompression: true,
          withData: true);

      if (result?.files != null) {
        selectedFiles = tempList;
        tempList = [];

        result.files.forEach((element) {
          selectedFiles.add(element);
        });
        if (appClosedSharedFiles.isNotEmpty) {
          appClosedSharedFiles.forEach((element) {
            selectedFiles.add(element);
          });
        }
      }

      calculateSize();

      setStatus(PICK_FILES, Status.Done);
    } catch (error) {
      setError(PICK_FILES, error.toString());
    }
  }

  calculateSize() async {
    totalSize = 0;
    selectedFiles?.forEach((element) {
      totalSize += element.size;
    });
  }

  void acceptFiles() async {
    setStatus(ACCEPT_FILES, Status.Loading);
    try {
      await ReceiveSharingIntent.getMediaStream().listen(
          (List<SharedMediaFile> value) {
        _sharedFiles = value;

        if (value.isNotEmpty) {
          value.forEach((element) async {
            File file = File(element.path);
            double length = double.parse(await file.length().toString());

            selectedFiles.add(PlatformFile(
                name: basename(file.path),
                path: file.path,
                size: length.round(),
                bytes: await file.readAsBytes()));
            await calculateSize();
          });

          print(
              "Shared:" + (_sharedFiles?.map((f) => f.path)?.join(",") ?? ""));
        }
      }, onError: (err) {
        print("getIntentDataStream error: $err");
      });

      // For sharing images coming from outside the app while the app is closed
      await ReceiveSharingIntent.getInitialMedia()
          .then((List<SharedMediaFile> value) {
        _sharedFiles = value;
        if (_sharedFiles != null && _sharedFiles.isNotEmpty) {
          _sharedFiles.forEach((element) async {
            var test = File(element.path);
            var length = await test.length();

            selectedFiles.add(PlatformFile(
                name: basename(test.path),
                path: test.path,
                size: length.round(),
                bytes: await test.readAsBytes()));
            await calculateSize();
          });
          print(
              "Shared:" + (_sharedFiles?.map((f) => f.path)?.join(",") ?? ""));
          BuildContext c = NavService.navKey.currentContext;
          Navigator.pushReplacementNamed(c, Routes.WELCOME_SCREEN);
        }
      });
      setStatus(ACCEPT_FILES, Status.Done);
    } catch (error) {
      setError(ACCEPT_FILES, error.toString());
    }
  }

  sendFiles(List<PlatformFile> selectedFiles,
      List<GroupContactsModel> contactList) async {
    setStatus(SEND_FILES, Status.Loading);
    try {
      temporaryContactList = [];
      contactList.forEach((element) {
        if (element.contactType == ContactsType.CONTACT) {
          bool flag = false;
          for (AtContact atContact in temporaryContactList) {
            if (atContact.toString() == element.contact.toString()) {
              flag = true;
            }
          }
          if (!flag) {
            temporaryContactList.add(element.contact);
          }
        } else if (element.contactType == ContactsType.GROUP) {
          element.group.members.forEach((contact) {
            bool flag = false;
            for (AtContact atContact in temporaryContactList) {
              if (atContact.toString() == contact.toString()) {
                flag = true;
              }
            }
            if (!flag) {
              temporaryContactList.add(contact);
            }
          });
        }
      });

      int id = DateTime.now().millisecondsSinceEpoch;
      temporaryContactList.forEach((contact) {
        // selectedFiles.forEach((file) {
        //   if (file == selectedFiles.first) {
        //     sentStatus = true;
        //   } else {
        //     sentStatus = null;
        //   }

        updateStatus(contact, id);
      });

      setStatus(SEND_FILES, Status.Done);
    } catch (error) {
      setError(SEND_FILES, error.toString());
    }
  }

  bool checkAtContactList(AtContact element) {
    return false;
  }

  static send(String contact, List selectedFiles, _backendService) async {
    selectedFiles.forEach((file) async {
      await _backendService.sendFile(contact, file.path);
    });
  }

  updateStatus(AtContact contact, int id) async {
    selectedFiles.forEach((element) {
      transferStatus.add(FileTransferStatus(
          contactName: contact.atSign,
          fileName: element.name,
          status: TransferStatus.PENDING,
          id: id));
      Provider.of<HistoryProvider>(NavService.navKey.currentContext,
              listen: false)
          .setFilesHistory(
              id: id,
              atSignName: contact.atSign,
              historyType: HistoryType.send,
              files: [
            FilesDetail(
              filePath: element.path,
              id: id,
              contactName: contact.atSign,
              size: double.parse(element.size.toString()),
              fileName: element.name.toString(),
              type: element.name.split('.').last,
            ),
          ]);
    });

    for (var i = 0; i < selectedFiles.length; i++) {
      print('before await $i');
      bool tempStatus =
          await _backendService.sendFile(contact.atSign, selectedFiles[i].path);
      print('after await $i==tempstatus===?$tempStatus');

      int index = transferStatus.indexWhere((element) =>
          element.fileName == selectedFiles[i].name &&
          contact.atSign == element.contactName);
      print('index===>$index');
      if (tempStatus) {
        transferStatus[index].status = TransferStatus.DONE;
      } else {
        transferStatus[index].status = TransferStatus.FAILED;
      }
      print('transferStatus===>${transferStatus[index]}');
    }
    print('transferStatus LASSSTTT===>${transferStatus.last}');
    // getStatus(id, contact.atSign);
  }

  TransferStatus getStatus(int id, String atSign) {
    TransferStatus status;
    transferStatus.forEach((element) {
      print('ID===>$id====$atSign===>${element.status}');
      if (element.id == id &&
          element.contactName == atSign &&
          status != TransferStatus.PENDING) {
        //     print('in here====${element.status}');
        //     if (element.status == TransferStatus.DONE) {
        //       status = TransferStatus.DONE;
        if (element.status == TransferStatus.PENDING) {
          status = TransferStatus.PENDING;
        } else if (element.status == TransferStatus.FAILED) {
          status = TransferStatus.FAILED;
        } else if (element.status != TransferStatus.FAILED) {
          status = TransferStatus.DONE;
        }
      }
    });
    print('r.runtimeType===>${status}');
    return status;
  }
}
