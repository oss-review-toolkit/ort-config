# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 CARIAD SE

from pathlib import Path

import yaml
from pydantic_settings import BaseSettings
from rich import print
from rich.panel import Panel


class Settings(BaseSettings):
    CLASSIFICATION_FILE: str = "cariad/license-classifications.yml"


settings: Settings = Settings()

# Load Cariad implementation
classification_path: Path = Path(settings.CLASSIFICATION_FILE)
if not classification_path.exists():
    print(
        "[bold yellow]WARNING[/bold yellow]: {classification_path} is not found.",
    )
    exit(1)
with classification_path.open() as f:
    data = yaml.safe_load(f)

categories: list[str] = list(map(lambda cat: cat["name"], data["categories"]))

for cat in data["categorizations"]:
    for entry in cat["categories"]:
        if entry not in categories:
            print(
                Panel.fit(
                    f"ERROR: Category [bold red]{entry}[/bold red] not exists for [bold yellow]{cat['id']}[/bold yellow]!",
                    border_style="red",
                )
            )
            exit(1)

print(
    Panel.fit("[bold green]All Categories validated[/bold green]", border_style="green")
)
