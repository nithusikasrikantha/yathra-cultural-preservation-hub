import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/cultural_map_dummy_data.dart';
import '../../models/cultural_place.dart';
import '../../widgets/map/cultural_map_widgets.dart';
import 'cultural_map_search_page.dart';
import 'cultural_place_detail_page.dart';

class CulturalMapPage extends StatefulWidget {
  const CulturalMapPage({super.key, required this.userRole});

  final String userRole;

  @override
  State<CulturalMapPage> createState() => _CulturalMapPageState();
}

class _CulturalMapPageState extends State<CulturalMapPage>
    with SingleTickerProviderStateMixin {
  static const _sriLankaCenter = LatLng(7.8731, 80.7718);
  static const _initialZoom = 6.8;

  final MapController _mapController = MapController();
  AnimationController? _cameraAnimationController;
  bool _mapReady = false;
  CulturalPlaceCategory? _quickCategory;
  Set<CulturalPlaceCategory> _categories = {};
  String? _province;
  String? _district;
  String _language = 'All';
  bool _withStories = false;
  bool _nearbyOnly = false;
  bool _isLoading = true;
  bool _hasError = false;
  bool _locationUnavailable = false;
  CulturalPlace? _selectedPlace;
  CulturalRegion? _selectedRegion;
  final Set<String> _locallySavedPlaceIds = {};

  bool get _canSavePlaces => widget.userRole != 'elder';

  bool get _hasActiveFilters =>
      _categories.isNotEmpty ||
      _province != null ||
      _district != null ||
      _language != 'All' ||
      _withStories ||
      _nearbyOnly;

  List<CulturalPlace> get _visiblePlaces {
    return CulturalMapDummyData.places
        .where((place) {
          if (_quickCategory != null &&
              !place.categories.contains(_quickCategory)) {
            return false;
          }
          if (_categories.isNotEmpty &&
              !place.categories.any(_categories.contains)) {
            return false;
          }
          if (_province != null && place.province != _province) return false;
          if (_district != null && place.district != _district) return false;
          if (_language != 'All' && !place.languages.contains(_language)) {
            return false;
          }
          if (_withStories && place.storyCount == 0) return false;
          if (_nearbyOnly && place.district != 'Jaffna') return false;
          if (_selectedRegion != null &&
              place.district != _selectedRegion!.name) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  @override
  void dispose() {
    _cameraAnimationController?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _animateMapTo({
    required double latitude,
    required double longitude,
    required double zoom,
  }) {
    if (!_mapReady) return;
    _cameraAnimationController?.dispose();

    final startCenter = _mapController.camera.center;
    final startZoom = _mapController.camera.zoom;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    final curve = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );
    final latitudeAnimation = Tween<double>(
      begin: startCenter.latitude,
      end: latitude,
    ).animate(curve);
    final longitudeAnimation = Tween<double>(
      begin: startCenter.longitude,
      end: longitude,
    ).animate(curve);
    final zoomAnimation = Tween<double>(
      begin: startZoom,
      end: zoom,
    ).animate(curve);

    controller.addListener(() {
      if (!_mapReady) return;
      _mapController.move(
        LatLng(latitudeAnimation.value, longitudeAnimation.value),
        zoomAnimation.value,
      );
    });
    _cameraAnimationController = controller;
    controller.forward();
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _quickCategory = null;
      _categories = {};
      _province = null;
      _district = null;
      _language = 'All';
      _withStories = false;
      _nearbyOnly = false;
      _selectedRegion = null;
      _selectedPlace = null;
    });
  }

  Future<void> _openSearch() async {
    final result = await Navigator.of(context).push<CulturalPlace>(
      MaterialPageRoute(builder: (_) => const CulturalMapSearchPage()),
    );
    if (!mounted || result == null) return;
    setState(() {
      _selectedRegion = null;
      _quickCategory = null;
      _categories = {};
      _province = null;
      _district = null;
      _language = 'All';
      _withStories = false;
      _nearbyOnly = false;
      _selectedPlace = result;
    });
    _animateMapTo(
      latitude: result.latitude,
      longitude: result.longitude,
      zoom: 13,
    );
  }

  Future<void> _openDetails(CulturalPlace place) async {
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => CulturalPlaceDetailPage(
          place: place,
          userRole: widget.userRole,
          initiallySaved: _locallySavedPlaceIds.contains(place.id),
        ),
      ),
    );
    if (!mounted) return;
    if (result is CulturalPlace) {
      setState(() => _selectedPlace = result);
      _animateMapTo(
        latitude: result.latitude,
        longitude: result.longitude,
        zoom: 13,
      );
    } else if (result is bool && _canSavePlaces) {
      setState(() {
        if (result) {
          _locallySavedPlaceIds.add(place.id);
        } else {
          _locallySavedPlaceIds.remove(place.id);
        }
      });
    }
  }

  Future<void> _showFilters() async {
    final result = await showModalBottomSheet<_MapFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: mapCardColor,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FilterSheet(
        initial: _MapFilters(
          categories: _categories,
          province: _province,
          district: _district,
          language: _language,
          withStories: _withStories,
          nearbyOnly: _nearbyOnly,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _categories = result.categories;
      _province = result.province;
      _district = result.district;
      _language = result.language;
      _withStories = result.withStories;
      _nearbyOnly = result.nearbyOnly;
      _selectedRegion = null;
      _selectedPlace = null;
    });
    if (result.district case final district?) {
      final districtPlaces = CulturalMapDummyData.places.where(
        (place) => place.district == district,
      );
      if (districtPlaces.isNotEmpty) {
        final place = districtPlaces.first;
        _animateMapTo(
          latitude: place.latitude,
          longitude: place.longitude,
          zoom: 11.5,
        );
      }
    }
  }

  Future<void> _showNearMe() async {
    final allow = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: mapCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 20),
              const CircleAvatar(
                radius: 28,
                backgroundColor: mapPeach,
                child: Icon(
                  Icons.near_me_outlined,
                  color: mapAccentBrown,
                  size: 29,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Allow location access?',
                style: TextStyle(
                  color: mapPrimaryBrown,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Location helps us show cultural places near you. The map remains available without it.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.4, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: mapAccentBrown,
                  ),
                  child: const Text('Allow Location'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(false),
                child: const Text('Maybe Later'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || allow != true) return;

    setState(() => _locationUnavailable = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Location is not connected in this preview. You can keep exploring the map.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mapBackgroundColor,
      appBar: const YathraMapHeader(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
              child: CulturalMapSearchBar(
                onTap: _openSearch,
                onFilter: _showFilters,
                hasActiveFilters: _hasActiveFilters,
              ),
            ),
            CulturalMapFilterChips(
              selected: _quickCategory,
              onSelected: (category) => setState(() {
                _quickCategory = category;
                _selectedPlace = null;
              }),
            ),
            const SizedBox(height: 9),
            _buildRegionStrip(),
            const SizedBox(height: 9),
            Expanded(child: _buildMapState()),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionStrip() {
    return SizedBox(
      height: 53,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: CulturalMapDummyData.regions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final region = CulturalMapDummyData.regions[index];
          final selected = _selectedRegion?.name == region.name;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedRegion = selected ? null : region;
                _selectedPlace = null;
              });
              if (selected) {
                _animateMapTo(
                  latitude: _sriLankaCenter.latitude,
                  longitude: _sriLankaCenter.longitude,
                  zoom: _initialZoom,
                );
              } else {
                _animateMapTo(
                  latitude: region.latitude,
                  longitude: region.longitude,
                  zoom: 11.5,
                );
              }
            },
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 132,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? mapAccentBrown : mapCardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? mapAccentBrown
                      : mapAccentBrown.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.public_rounded,
                    size: 19,
                    color: selected ? Colors.white : mapAccentBrown,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          region.name,
                          style: TextStyle(
                            color: selected ? Colors.white : mapPrimaryBrown,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                        Text(
                          '${region.storyCount} stories',
                          style: TextStyle(
                            color: selected ? Colors.white70 : Colors.black45,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapState() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: mapAccentBrown),
            SizedBox(height: 12),
            Text('Preparing the cultural map...'),
          ],
        ),
      );
    }
    if (_hasError) {
      return CulturalMapEmptyState(
        title: "We couldn't load cultural places.",
        message: 'Please check again in a moment.',
        actionLabel: 'Try Again',
        onAction: _loadPlaces,
        isError: true,
      );
    }
    if (_visiblePlaces.isEmpty) {
      return CulturalMapEmptyState(
        title: 'No cultural places found',
        message: 'Try changing your search or filters.',
        actionLabel: 'Clear Filters',
        onAction: _clearFilters,
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: Stack(
        children: [
          Positioned.fill(
            child: _CulturalMapCanvas(
              controller: _mapController,
              places: _visiblePlaces,
              selectedPlace: _selectedPlace,
              onMapReady: () => _mapReady = true,
              onSelect: (place) => setState(() => _selectedPlace = place),
            ),
          ),
          Positioned(
            top: 47,
            right: 14,
            child: FloatingActionButton.small(
              heroTag: 'cultural-map-near-me',
              onPressed: _showNearMe,
              tooltip: 'Find places near me',
              backgroundColor: mapCardColor,
              foregroundColor: mapAccentBrown,
              child: Icon(
                _locationUnavailable
                    ? Icons.location_disabled_outlined
                    : Icons.near_me_outlined,
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: mapCardColor.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_visiblePlaces.length} cultural places',
                style: const TextStyle(
                  color: mapPrimaryBrown,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (_selectedPlace case final place?)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CulturalMapMarkerPreview(
                place: place,
                canSave: _canSavePlaces,
                isSaved: _locallySavedPlaceIds.contains(place.id),
                onDismiss: () => setState(() => _selectedPlace = null),
                onSave: () => setState(() {
                  if (!_locallySavedPlaceIds.remove(place.id)) {
                    _locallySavedPlaceIds.add(place.id);
                  }
                }),
                onViewDetails: () => _openDetails(place),
              ),
            ),
        ],
      ),
    );
  }
}

class _CulturalMapCanvas extends StatelessWidget {
  const _CulturalMapCanvas({
    required this.controller,
    required this.places,
    required this.selectedPlace,
    required this.onMapReady,
    required this.onSelect,
  });

  final MapController controller;
  final List<CulturalPlace> places;
  final CulturalPlace? selectedPlace;
  final VoidCallback onMapReady;
  final ValueChanged<CulturalPlace> onSelect;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: _CulturalMapPageState._sriLankaCenter,
        initialZoom: _CulturalMapPageState._initialZoom,
        minZoom: 5,
        maxZoom: 18,
        backgroundColor: const Color(0xFFDCE9E5),
        keepAlive: true,
        onMapReady: onMapReady,
        onTap: (_, _) => FocusManager.instance.primaryFocus?.unfocus(),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.frontend',
          maxNativeZoom: 19,
        ),
        MarkerLayer(
          markers: places
              .map(
                (place) => Marker(
                  point: LatLng(place.latitude, place.longitude),
                  width: selectedPlace?.id == place.id ? 48 : 40,
                  height: selectedPlace?.id == place.id ? 48 : 40,
                  child: _MapMarker(
                    place: place,
                    isSelected: selectedPlace?.id == place.id,
                    onTap: () => onSelect(place),
                  ),
                ),
              )
              .toList(growable: false),
        ),
        const SimpleAttributionWidget(
          source: Text('OpenStreetMap contributors'),
          alignment: Alignment.topRight,
          backgroundColor: Color(0xDDFFFFFF),
        ),
      ],
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.place,
    required this.isSelected,
    required this.onTap,
  });

  final CulturalPlace place;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${place.name}, ${place.primaryCategory.label}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: isSelected ? 48 : 40,
          height: isSelected ? 48 : 40,
          decoration: BoxDecoration(
            color: isSelected ? mapPrimaryBrown : mapAccentBrown,
            shape: BoxShape.circle,
            border: Border.all(color: mapCardColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: isSelected ? 10 : 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            place.primaryCategory.icon,
            color: Colors.white,
            size: isSelected ? 24 : 20,
          ),
        ),
      ),
    );
  }
}

class _MapFilters {
  const _MapFilters({
    required this.categories,
    required this.province,
    required this.district,
    required this.language,
    required this.withStories,
    required this.nearbyOnly,
  });

  final Set<CulturalPlaceCategory> categories;
  final String? province;
  final String? district;
  final String language;
  final bool withStories;
  final bool nearbyOnly;
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final _MapFilters initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Set<CulturalPlaceCategory> _categories;
  late String? _province;
  late String? _district;
  late String _language;
  late bool _withStories;
  late bool _nearbyOnly;

  static const provinces = ['Northern', 'Central', 'Southern'];
  static const districts = ['Jaffna', 'Kandy', 'Galle'];
  static const languages = ['All', 'Tamil', 'Sinhala', 'English'];

  @override
  void initState() {
    super.initState();
    _categories = Set.of(widget.initial.categories);
    _province = widget.initial.province;
    _district = widget.initial.district;
    _language = widget.initial.language;
    _withStories = widget.initial.withStories;
    _nearbyOnly = widget.initial.nearbyOnly;
  }

  void _reset() {
    setState(() {
      _categories = {};
      _province = null;
      _district = null;
      _language = 'All';
      _withStories = false;
      _nearbyOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 10, 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filter Cultural Map',
                    style: TextStyle(
                      color: mapPrimaryBrown,
                      fontWeight: FontWeight.bold,
                      fontSize: 21,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                _label('CATEGORY'),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: CulturalPlaceCategory.values
                      .map(
                        (category) => FilterChip(
                          label: Text(category.label),
                          selected: _categories.contains(category),
                          onSelected: (selected) => setState(() {
                            selected
                                ? _categories.add(category)
                                : _categories.remove(category);
                          }),
                          selectedColor: mapPeach,
                          checkmarkColor: mapAccentBrown,
                          side: BorderSide(
                            color: mapAccentBrown.withValues(alpha: 0.18),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 24),
                _label('REGION / DISTRICT'),
                const SizedBox(height: 9),
                DropdownButtonFormField<String>(
                  initialValue: _province,
                  decoration: const InputDecoration(
                    labelText: 'Province',
                    fillColor: Color(0xFFF7F1E8),
                  ),
                  items: provinces
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() {
                    _province = value;
                    _district = null;
                  }),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: districts
                      .map(
                        (district) => ChoiceChip(
                          label: Text(district),
                          selected: _district == district,
                          onSelected: (selected) => setState(
                            () => _district = selected ? district : null,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 24),
                _label('LANGUAGE'),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 8,
                  children: languages
                      .map(
                        (language) => ChoiceChip(
                          label: Text(language),
                          selected: _language == language,
                          onSelected: (_) =>
                              setState(() => _language = language),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 24),
                _label('OTHER'),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: mapAccentBrown,
                  title: const Text('Places with stories'),
                  value: _withStories,
                  onChanged: (value) => setState(() => _withStories = value),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: mapAccentBrown,
                  title: const Text('Nearby places'),
                  subtitle: const Text(
                    'Uses a preview area until location is connected.',
                  ),
                  value: _nearbyOnly,
                  onChanged: (value) => setState(() => _nearbyOnly = value),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              color: mapCardColor,
              border: Border(
                top: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(
                        _MapFilters(
                          categories: Set.unmodifiable(_categories),
                          province: _province,
                          district: _district,
                          language: _language,
                          withStories: _withStories,
                          nearbyOnly: _nearbyOnly,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: mapAccentBrown,
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      color: mapAccentBrown,
      fontSize: 11,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.1,
    ),
  );
}
