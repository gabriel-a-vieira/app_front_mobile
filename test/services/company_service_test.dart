import 'package:app_front_mobile/services/company_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the cityId round-trip the company form depends on: the admin
/// detail response carries `cityId` so the edit form can preselect the city
/// in CityLookupModal, and the save request sends it back so the backend
/// resolves the city by id instead of by exact name + UF.
void main() {
  group('CompanyDetail.fromJson', () {
    test('reads cityId alongside city and state', () {
      final detail = CompanyDetail.fromJson({
        'id': 'company-1',
        'cityId': 'city-1',
        'city': 'Campinas',
        'state': 'SP',
      });

      expect(detail.cityId, 'city-1');
      expect(detail.city, 'Campinas');
      expect(detail.state, 'SP');
    });

    test('defaults cityId to empty when the API does not send it', () {
      final detail = CompanyDetail.fromJson({'id': 'company-1'});

      expect(detail.cityId, '');
    });
  });

  group('CompanySaveRequest.toJson', () {
    test('sends cityId together with city name and state', () {
      const request = CompanySaveRequest(
        legalName: 'Empresa Teste LTDA',
        tradeName: 'Empresa Teste',
        cnpj: '12345678000190',
        type: 'OTHER',
        status: 'ACTIVE',
        imageUrl: '',
        zipCode: '',
        street: '',
        number: '',
        district: '',
        cityId: 'city-1',
        city: 'Campinas',
        state: 'SP',
        complement: '',
        instagramUrl: '',
        facebookUrl: '',
        websiteUrl: '',
        tiktokUrl: '',
        paymentMethods: [],
        amenities: [],
        openingHours: [],
      );

      final json = request.toJson();

      expect(json['cityId'], 'city-1');
      expect(json['city'], 'Campinas');
      expect(json['state'], 'SP');
    });
  });
}
