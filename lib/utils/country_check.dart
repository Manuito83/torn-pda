import 'package:flutter/material.dart';

/// Takes a player status and returns the country
/// Active travels are considered as being abroad in the destination country
String countryCheck({@required String state, @required String description}) {
  try {
    // Visiting
    if (state == "Abroad") {
      return description.split("In ")[1];
    }

    // Travelling
    if (state == "Traveling") {
      if (description.contains("Returning to Torn")) {
        return "Torn";
      }
      return description.split("Traveling to ")[1];
    }

    // Abroad hospital
    if (state == "Hospital") {
      if (description.contains("In a Swiss hospital")) {
        return "Switzerland";
      } else if (description.contains("In an Emirati hospital")) {
        return "UAE";
      } else if (description.contains("In a British hospital")) {
        return "United Kingdom";
      } else if (description.contains("In a Chinese hospital")) {
        return "China";
      } else if (description.contains("In a South African hospital")) {
        return "South Africa";
      } else if (description.contains("In an Argentinian hospital")) {
        return "Argentina";
      } else if (description.contains("In a Caymanian hospital")) {
        return "Cayman Islands";
      } else if (description.contains("In a Canadian hospital")) {
        return "Canada";
      } else if (description.contains("In a Mexican hospital")) {
        return "Mexico";
      } else if (description.contains("In a Japanese hospital")) {
        return "Japan";
      } else if (description.contains("In a Hawaiian hospital")) {
        return "Hawaii";
      }
      return "Torn";
    }
  } catch (e) {
    return "error";
  }

  return "Torn";
}

/// Takes a player status and returns if the player is traveling (active flight)
bool travelingCheck({@required String state}) {
  try {
    // Travelling
    if (state == "Traveling") {
      return true;
    }
  } catch (e) {
    //
  }

  return false;
}
