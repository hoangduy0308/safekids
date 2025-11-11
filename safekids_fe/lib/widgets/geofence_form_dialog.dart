import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

class GeofenceFormDialog extends StatefulWidget {
  final LatLng center;
  final double radius;
  final List<User> linkedChildren;
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? existingData;

  const GeofenceFormDialog({
    Key? key,
    required this.center,
    required this.radius,
    required this.linkedChildren,
    required this.onSave,
    this.existingData,
  }) : super(key: key);

  @override
  State<GeofenceFormDialog> createState() => _GeofenceFormDialogState();
}

class _GeofenceFormDialogState extends State<GeofenceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _type = 'safe';
  List<String> _selectedChildren = [];
  double _radius = 100;

  @override
  void initState() {
    super.initState();
    _radius = widget.radius;
    _selectedChildren = [];

    if (widget.existingData != null) {
      _nameController.text = widget.existingData!['name'] ?? '';
      _type = widget.existingData!['type'] ?? 'safe';
      _radius = widget.existingData!['radius']?.toDouble() ?? 100;
      _selectedChildren = List<String>.from(
        widget.existingData!['linkedChildren'] ?? [],
      );
    }

    print('[FormInit] Linked children count: ${widget.linkedChildren.length}');
    print('[FormInit] Selected children: $_selectedChildren');
    for (var child in widget.linkedChildren) {
      print(
        '[FormInit] Child: id=${child.id}, name=${child.name}, fullName=${child.fullName}',
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.parentPrimaryLight,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.white),
                  SizedBox(width: AppSpacing.md),
                  Text(
                    widget.existingData != null
                        ? 'Chỉnh sửa vùng'
                        : 'Tạo vùng mới',
                    style: AppTypography.h2.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),

            Form(
              key: _formKey,
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Tên vùng *',
                        hintText: 'vd: Trường học, Nhà...',
                        prefixIcon: Icon(Icons.label),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty == true) {
                          return 'Vui lòng nhập tên vùng';
                        }
                        if (value != null && value.length > 50) {
                          return 'Tên vùng tối đa 50 ký tự';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: AppSpacing.lg),

                    Text(
                      'Loại vùng',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),

                    RadioListTile<String>(
                      title: Text('Vùng an toàn', style: AppTypography.body),
                      subtitle: Text(
                        'Cảnh báo khi con rời khỏi vùng',
                        style: AppTypography.caption,
                      ),
                      value: 'safe',
                      groupValue: _type,
                      onChanged: (val) => setState(() => _type = val!),
                      secondary: Icon(Icons.shield, color: Colors.green),
                    ),

                    RadioListTile<String>(
                      title: Text('Vùng nguy hiểm', style: AppTypography.body),
                      subtitle: Text(
                        'Cảnh báo khi con vào vùng',
                        style: AppTypography.caption,
                      ),
                      value: 'danger',
                      groupValue: _type,
                      onChanged: (val) => setState(() => _type = val!),
                      secondary: Icon(Icons.warning, color: Colors.red),
                    ),

                    SizedBox(height: AppSpacing.lg),

                    Text(
                      'Bán kính vùng: ${_radius.toInt()}m',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    Slider(
                      value: _radius,
                      min: 50,
                      max: 1000,
                      divisions: 19,
                      label: '${_radius.toInt()}m',
                      onChanged: (value) => setState(() => _radius = value),
                    ),

                    SizedBox(height: AppSpacing.lg),

                    Text(
                      'Áp dụng cho *',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),

                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: widget.linkedChildren.isEmpty
                          ? Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: Text(
                                'Không có trẻ em liên kết',
                                style: AppTypography.caption.copyWith(
                                  color: Colors.red,
                                ),
                              ),
                            )
                          : Column(
                              children: widget.linkedChildren.map((child) {
                                return CheckboxListTile(
                                  title: Text(
                                    child.name,
                                    style: AppTypography.body,
                                  ),
                                  value: _selectedChildren.contains(child.id),
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        _selectedChildren.add(child.id);
                                      } else {
                                        _selectedChildren.remove(child.id);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Hủy'),
                  ),
                  SizedBox(width: AppSpacing.md),
                  ElevatedButton(
                    onPressed: _handleSave,
                    child: Text(
                      widget.existingData != null ? 'Cập nhật' : 'Lưu',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSave() {
    print('[FormSave] Validate form');
    if (_formKey.currentState!.validate()) {
      print('[FormSave] Form valid');
      print('[FormSave] Selected children: $_selectedChildren');

      if (_selectedChildren.isEmpty) {
        print('[FormSave] Lỗi: Không có trẻ em được chọn');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vui lòng chọn ít nhất một trẻ em'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final data = {
        'name': _nameController.text,
        'type': _type,
        'linkedChildren': _selectedChildren,
        'radius': _radius,
      };
      print('[FormSave] Gửi dữ liệu: $data');

      widget.onSave(data);
      Navigator.pop(context);
    } else {
      print('[FormSave] Form không valid');
    }
  }
}
