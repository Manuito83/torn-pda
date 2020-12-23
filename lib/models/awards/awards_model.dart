import 'package:flutter/material.dart';

class Award {
  Award({
    this.name = "",
    this.description = "",
    this.category = '',
    this.subCategory = "",
    this.type = "",
    this.image,
    this.achieve = 0,
    this.circulation = 0,
    this.rScore = 0,
    this.rarity = "",
    this.goal = 0,
    this.current = 0,
    this.dateAwarded = 0,
    this.daysLeft = 0,
    this.comment = "",
    this.pinned,
    this.doubleMerit,
    this.tripleMerit,
    this.nextCrime,
  });

  String name;
  String description;
  String category;
  String subCategory;
  String type;
  Image image;
  double achieve;
  double circulation;
  double rScore;
  String rarity;
  double goal;
  double current;
  double dateAwarded;
  double daysLeft;
  String comment;
  bool pinned;
  bool doubleMerit;
  bool tripleMerit;
  bool nextCrime;
}