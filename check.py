#!/usr/bin/env python3
import ast
import os
import sys


def main():
    check_working_directory()
    check_corrections()


def check_corrections():
    for directory, _, _ in os.walk("."):
        if directory != ".":
            check_correction(directory)


def check_correction(directory):
    try:
        open(os.path.join(directory, "Korrektur.pdf"))
    except IOError:
        print(f"Keine Korrektur.pdf für Abgabe {directory}")
    try:
        f = open(os.path.join(directory, "Korrektur.yml"))
        lines = f.readlines()
        check_corrected_and_points_given(directory, lines)

    except IOError:
        print(f"Keine Korrektur.yml für Abgabe {directory}")


def check_corrected_and_points_given(directory, lines):
    corrected = False
    points_given = []
    for line in lines:
        if "corrected: true" in line:
            corrected = True
        if "points:" in line:
            points_given = ast.literal_eval(line.split(" ")[-1])
        if "erreichbare" in line:
            points_possible = [int(point) for point in line.split(" ")[-1].split("+")]
            for given, possible in zip(points_given, points_possible):
                if not (0 <= given <= possible) or (int(given) != given):
                    print(f"{directory} hat eine ungültige Punktzahl: {given}/{possible} Punkte gegeben")
    if not corrected:
        print(f"Korrektur von {directory} nicht als fertig markiert")
    if not points_given:
        print(f"Korrektur von {directory} hat keine Punkte")


def check_working_directory():
    try:
        open("workspace.yml")
    except IOError:
        print("workspace.yml nicht gefunden. Bist du im richtigen Arbeitsverzeichnis?")
        sys.exit(1)


if __name__ == '__main__':
    main()
