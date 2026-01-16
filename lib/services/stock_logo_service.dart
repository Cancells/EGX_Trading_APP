import 'package:flutter/material.dart';

/// Stock Logo Service
/// Uses Clearbit's free logo API to fetch company logos
class StockLogoService {
  static final StockLogoService _instance = StockLogoService._internal();
  factory StockLogoService() => _instance;
  StockLogoService._internal();

  /// Clearbit logo API base URL
  static const String _clearbitLogoUrl = 'https://logo.clearbit.com';

  /// Map of Egyptian stock symbols to their company websites
  /// This serves as our database of company websites
  static const Map<String, String> _stockWebsites = {
    // Banks
    'COMI.CA': 'cibeg.com',
    'CIEB.CA': 'credit-agricole.com.eg',
    'ADIB.CA': 'adib.eg',
    'HDBK.CA': 'hdb-egy.com',
    
    // Real Estate
    'TMGH.CA': 'talaatmoustafa.com',
    'PHDC.CA': 'palmhillsdevelopments.com',
    'HELI.CA': 'heliopoliscompany.com',
    'ORHD.CA': 'orascomdh.com',
    'EMFD.CA': 'emaarmisr.com',
    'PORT.CA': 'portogroup.com.eg',
    
    // Telecom
    'ETEL.CA': 'te.eg',
    
    // Fintech
    'FWRY.CA': 'fawry.com',
    
    // Financial Services
    'HRHO.CA': 'efghermes.com',
    'BTFH.CA': 'beltoneholding.com',
    'CNFN.CA': 'contactcars.com',
    
    // Investments
    'EKHO.CA': 'ekholding.com',
    'CCAP.CA': 'qalaaholdings.com',
    
    // Basic Resources
    'ABUK.CA': 'aboukir.com',
    'MFPC.CA': 'mopco-eg.com',
    'ESRS.CA': 'ezzsteel.com',
    'EGAL.CA': 'egyptalum.com.eg',
    'KIMA.CA': 'kaborgroup.com',
    
    // Industrial
    'SWDY.CA': 'elsewedy.com',
    
    // Healthcare
    'ISPH.CA': 'ibnsinapharma.com',
    'CLHO.CA': 'cleopatrahospitals.com',
    'RMDA.CA': 'rameda-pharma.com',
    'SPMD.CA': 'speedmedical.net',
    
    // Technology
    'EFIH.CA': 'efinance.com.eg',
    'RAYA.CA': 'rayacorp.com',
    'RACC.CA': 'rayacc.com',
    
    // Energy
    'AMOC.CA': 'amoc-eg.com',
    'SKPC.CA': 'sidpec.com',
    
    // Food & Beverage
    'JUFO.CA': 'juhayna.com',
    'DOMT.CA': 'domty.com',
    'EFID.CA': 'edita.com.eg',
    'OLFI.CA': 'obourland.com',
    
    // Textiles
    'ORWE.CA': 'orientalweavers.com',
    'DSCW.CA': 'dicesportswear.com',
    
    // Construction
    'ORAS.CA': 'orascom.com',
    
    // Building Materials
    'ARCC.CA': 'arabcement.com',
    
    // Automotive
    'AUTO.CA': 'gbauto.com.eg',
    
    // Tobacco
    'EAST.CA': 'easternco.com.eg',
    
    // Education
    'CIRA.CA': 'cira.com.eg',
    
    // Tourism
    'EGTS.CA': 'egyptianresorts.com',
  };

  /// Get the logo URL for a stock symbol using Clearbit
  /// Returns null if the symbol doesn't have a known website
  String? getLogoUrl(String symbol) {
    final hostname = _stockWebsites[symbol];
    if (hostname == null) return null;
    return '$_clearbitLogoUrl/$hostname';
  }

  /// Get the hostname for a stock symbol
  String? getHostname(String symbol) {
    return _stockWebsites[symbol];
  }

  /// Check if we have a logo URL for this symbol
  bool hasLogo(String symbol) {
    return _stockWebsites.containsKey(symbol);
  }

  /// Extract hostname from a full URL
  /// e.g., "https://www.cibeg.com" -> "cibeg.com"
  static String extractHostname(String url) {
    String hostname = url.toLowerCase().trim();
    
    // Remove protocol
    hostname = hostname.replaceFirst(RegExp(r'^https?://'), '');
    
    // Remove www.
    hostname = hostname.replaceFirst(RegExp(r'^www\.'), '');
    
    // Remove trailing slash and path
    final slashIndex = hostname.indexOf('/');
    if (slashIndex != -1) {
      hostname = hostname.substring(0, slashIndex);
    }
    
    return hostname;
  }

  /// Build Clearbit logo URL from a website URL
  static String buildLogoUrl(String websiteUrl) {
    final hostname = extractHostname(websiteUrl);
    return '$_clearbitLogoUrl/$hostname';
  }

  /// Get a color for fallback avatar based on symbol
  static Color getColorForSymbol(String symbol) {
    // Generate a consistent color based on the symbol
    final hash = symbol.hashCode;
    final colors = [
      const Color(0xFF1E88E5), // Blue
      const Color(0xFF43A047), // Green
      const Color(0xFFE53935), // Red
      const Color(0xFF8E24AA), // Purple
      const Color(0xFFFB8C00), // Orange
      const Color(0xFF00897B), // Teal
      const Color(0xFF3949AB), // Indigo
      const Color(0xFF6D4C41), // Brown
      const Color(0xFF546E7A), // Blue Grey
      const Color(0xFFD81B60), // Pink
    ];
    return colors[hash.abs() % colors.length];
  }

  /// Get initials from stock name for fallback
  static String getInitials(String name) {
    final words = name.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    // Take first letter of first two significant words
    final significant = words.where((w) => 
      !['for', 'and', 'the', 'of', 'in', '&'].contains(w.toLowerCase())
    ).toList();
    if (significant.length >= 2) {
      return '${significant[0][0]}${significant[1][0]}'.toUpperCase();
    }
    return words[0].substring(0, 1).toUpperCase();
  }
}
