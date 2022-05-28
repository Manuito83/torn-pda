import '../models/profile/own_profile_basic.dart';

/// Takes a player status and returns the country
/// Active travels are considered as being abroad in the destination country
String countryCheck(Status status) {
  try {
    // Visiting
    if (status.state == "Abroad") {
      return status.description.split("In ")[1];
    }

    // Travelling
    if (status.state == "Traveling") {
      if (status.description.contains("Returning to Torn")) {
        return "Torn";
      }
      return status.description.split("Traveling to ")[1];
    }

    // Abroad hospital
    if (status.state == "Hospital") {
      if (status.description.contains("In a Swiss hospital")) {
        return "Switzerland";
      } else if (status.description.contains("In an Emirati hospital")) {
        return "UAE";
      } else if (status.description.contains("In a British hospital")) {
        return "United Kingdom";
      } else if (status.description.contains("In a Chinese hospital")) {
        return "China";
      } else if (status.description.contains("In a South African hospital")) {
        return "South Africa";
      } else if (status.description.contains("In an Argentinian hospital")) {
        return "Argentina";
      } else if (status.description.contains("In a Caymanian hospital")) {
        return "Cayman Islands";
      } else if (status.description.contains("In a Canadian hospital")) {
        return "Canada";
      } else if (status.description.contains("In a Mexican hospital")) {
        return "Mexico";
      } else if (status.description.contains("In a Japanese hospital")) {
        return "Japan";
      } else if (status.description.contains("In a Hawaiian hospital")) {
        return "Hawaii";
      }
      return "Torn";
    }
  } catch (e) {
    return "error";
  }

  return "Torn";
}
