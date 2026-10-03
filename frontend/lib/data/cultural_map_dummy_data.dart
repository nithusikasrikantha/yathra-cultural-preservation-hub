import '../models/cultural_place.dart';

/// Temporary place catalogue used until a cultural places API is available.
abstract final class CulturalMapDummyData {
  static const places = <CulturalPlace>[
    CulturalPlace(
      id: 'nallur-temple',
      name: 'Nallur Kandaswamy Temple',
      description:
          'A landmark Hindu temple in Jaffna, known for its annual festival, sacred rituals, and enduring place in Tamil cultural life.',
      province: 'Northern',
      district: 'Jaffna',
      categories: [
        CulturalPlaceCategory.temple,
        CulturalPlaceCategory.heritage,
      ],
      latitude: 9.6744,
      longitude: 80.0299,
      tags: ['Tamil Culture', 'Architecture', 'Worship'],
      languages: ['Tamil', 'English'],
      storyCount: 12,
      imageAssetPath: 'assets/images/youth_dummy/village_harvest_festival.png',
      relatedStoryIds: ['youth-dummy-village-harvest-festival'],
      traditions: [
        'The annual Nallur festival brings together processions, music, and community vows.',
        'Visitors observe traditional dress and temple customs within the sacred grounds.',
      ],
    ),
    CulturalPlace(
      id: 'jaffna-fort',
      name: 'Jaffna Fort',
      description:
          'A coastal fort whose layered architecture reflects centuries of regional encounters and the changing history of Jaffna.',
      province: 'Northern',
      district: 'Jaffna',
      categories: [
        CulturalPlaceCategory.historical,
        CulturalPlaceCategory.heritage,
      ],
      latitude: 9.6621,
      longitude: 80.0089,
      tags: ['Fort', 'Architecture', 'History'],
      languages: ['Tamil', 'Sinhala', 'English'],
      storyCount: 8,
      traditions: [
        'Oral histories remember the fort as both a landmark and a witness to changing rule.',
      ],
    ),
    CulturalPlace(
      id: 'keerimalai-springs',
      name: 'Keerimalai Sacred Springs',
      description:
          'Historic mineral springs beside the northern coast, connected with pilgrimage, wellbeing, and local legend.',
      province: 'Northern',
      district: 'Jaffna',
      categories: [
        CulturalPlaceCategory.heritage,
        CulturalPlaceCategory.folklore,
      ],
      latitude: 9.8147,
      longitude: 80.0130,
      tags: ['Sacred Water', 'Legend', 'Coast'],
      languages: ['Tamil', 'English'],
      storyCount: 6,
      traditions: [
        'Families visit the springs as part of pilgrimage and remembrance practices.',
      ],
    ),
    CulturalPlace(
      id: 'naguleswaram-temple',
      name: 'Naguleswaram Temple',
      description:
          'One of Sri Lanka’s ancient Saiva shrines, closely connected with Keerimalai and northern pilgrimage traditions.',
      province: 'Northern',
      district: 'Jaffna',
      categories: [CulturalPlaceCategory.temple],
      latitude: 9.8155,
      longitude: 80.0117,
      tags: ['Saiva', 'Pilgrimage', 'Tamil Culture'],
      languages: ['Tamil', 'English'],
      storyCount: 7,
      traditions: [
        'Seasonal worship links the temple with the nearby sacred springs.',
      ],
    ),
    CulturalPlace(
      id: 'temple-of-the-tooth',
      name: 'Temple of the Sacred Tooth Relic',
      description:
          'A revered Buddhist temple within Kandy’s historic royal complex and a focal point of living ritual tradition.',
      province: 'Central',
      district: 'Kandy',
      categories: [
        CulturalPlaceCategory.temple,
        CulturalPlaceCategory.heritage,
      ],
      latitude: 7.2936,
      longitude: 80.6413,
      tags: ['Buddhist Culture', 'Esala Perahera', 'Royal Heritage'],
      languages: ['Sinhala', 'Tamil', 'English'],
      storyCount: 18,
      traditions: [
        'Daily ceremonial offerings continue a long tradition of devotion.',
        'The Esala Perahera brings dancers, drummers, and processional arts to Kandy.',
      ],
    ),
    CulturalPlace(
      id: 'galle-fort',
      name: 'Galle Fort',
      description:
          'A living fortified town where streets, homes, places of worship, and craft traditions preserve a layered coastal identity.',
      province: 'Southern',
      district: 'Galle',
      categories: [
        CulturalPlaceCategory.historical,
        CulturalPlaceCategory.heritage,
      ],
      latitude: 6.0260,
      longitude: 80.2170,
      tags: ['Coastal Heritage', 'Architecture', 'Crafts'],
      languages: ['Sinhala', 'Tamil', 'English'],
      storyCount: 15,
      traditions: [
        'Lacework, gem craft, and food traditions remain part of the fort community.',
      ],
    ),
    CulturalPlace(
      id: 'jaffna-food-quarter',
      name: 'Jaffna Traditional Food Quarter',
      description:
          'A discovery stop celebrating northern recipes, palmyrah ingredients, and food memories passed through families.',
      province: 'Northern',
      district: 'Jaffna',
      categories: [CulturalPlaceCategory.food],
      latitude: 9.6615,
      longitude: 80.0255,
      tags: ['Food', 'Palmyrah', 'Recipes'],
      languages: ['Tamil', 'English'],
      storyCount: 9,
      imageAssetPath: 'assets/images/youth_dummy/traditional_jaffna_recipe.png',
      relatedStoryIds: ['youth-dummy-traditional-jaffna-recipe'],
      traditions: [
        'Recipes use local spices and palmyrah products, with techniques shared across generations.',
      ],
    ),
    CulturalPlace(
      id: 'trincomalee-fort-frederick',
      name: 'Fort Frederick, Trincomalee',
      description:
          'A historic fort on the eastern coast, forming part of Trincomalee’s layered maritime and cultural landscape.',
      province: 'Eastern',
      district: 'Trincomalee',
      categories: [
        CulturalPlaceCategory.historical,
        CulturalPlaceCategory.heritage,
      ],
      latitude: 8.5768,
      longitude: 81.2437,
      tags: ['Eastern Coast', 'Fort', 'Maritime History'],
      languages: ['Tamil', 'Sinhala', 'English'],
      storyCount: 10,
      traditions: [
        'Local narratives connect the fort precinct with pilgrimage, trade, and eastern coastal life.',
      ],
    ),
    CulturalPlace(
      id: 'mannar-fort',
      name: 'Mannar Fort',
      description:
          'A north-western coastal landmark reflecting Mannar’s long connections with seafaring, trade, and island communities.',
      province: 'Northern',
      district: 'Mannar',
      categories: [
        CulturalPlaceCategory.historical,
        CulturalPlaceCategory.heritage,
      ],
      latitude: 8.9786,
      longitude: 79.9168,
      tags: ['North-west Coast', 'Fort', 'Trade'],
      languages: ['Tamil', 'Sinhala', 'English'],
      storyCount: 7,
      traditions: [
        'Fishing, island travel, and trading memories shape the cultural stories of Mannar.',
      ],
    ),
  ];

  static const regions = <CulturalRegion>[
    CulturalRegion(
      name: 'Jaffna',
      province: 'Northern',
      storyCount: 42,
      latitude: 9.6615,
      longitude: 80.0255,
    ),
    CulturalRegion(
      name: 'Kandy',
      province: 'Central',
      storyCount: 28,
      latitude: 7.2906,
      longitude: 80.6337,
    ),
    CulturalRegion(
      name: 'Galle',
      province: 'Southern',
      storyCount: 21,
      latitude: 6.0329,
      longitude: 80.2168,
    ),
  ];
}
