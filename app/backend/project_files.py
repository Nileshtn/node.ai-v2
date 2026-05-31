from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from PySide6.QtCore import QObject, Slot
from PySide6.QtWidgets import QFileDialog


class ProjectFiles(QObject):
    PROJECT_FORMAT = "node.ai.project"
    PROJECT_VERSION = 1
    FILE_FILTER = "Node.ai Project (*.nai)"

    @Slot("QVariant", str, result="QVariant")
    def saveProject(self, project: Any, path: str) -> dict[str, Any]:
        if not path:
            return self.saveProjectAs(project)

        return self._save_project(project, path)

    @Slot("QVariant", result="QVariant")
    def saveProjectAs(self, project: Any) -> dict[str, Any]:
        path, _ = QFileDialog.getSaveFileName(
            None,
            "Save Node.ai Project",
            "",
            self.FILE_FILTER,
        )

        if not path:
            return self._cancelled_result("Save cancelled.")

        return self._save_project(project, path)

    @Slot(str, result="QVariant")
    def openProject(self, path: str) -> dict[str, Any]:
        return self._open_project(path)

    @Slot(result="QVariant")
    def openProjectDialog(self) -> dict[str, Any]:
        path, _ = QFileDialog.getOpenFileName(
            None,
            "Open Node.ai Project",
            "",
            self.FILE_FILTER,
        )

        if not path:
            return self._cancelled_result("Open cancelled.")

        return self._open_project(path)

    def _save_project(self, project: Any, path: str) -> dict[str, Any]:
        project_data = self._as_dict(project)
        validation_error = self._validate_project(project_data)

        if validation_error:
            return self._error_result(validation_error)

        project_path = self._nai_path(path)

        try:
            project_path.write_text(
                json.dumps(project_data, indent=2),
                encoding="utf-8",
            )
        except OSError as error:
            return self._error_result(f"Could not save project: {error}")

        return {
            "ok": True,
            "path": str(project_path),
            "project": project_data,
            "message": f"Saved {project_path.name}",
        }

    def _open_project(self, path: str) -> dict[str, Any]:
        project_path = Path(path)

        try:
            project_data = json.loads(project_path.read_text(encoding="utf-8"))
        except OSError as error:
            return self._error_result(f"Could not open project: {error}")
        except json.JSONDecodeError as error:
            return self._error_result(f"Invalid project file: {error}")

        validation_error = self._validate_project(project_data)

        if validation_error:
            return self._error_result(validation_error)

        return {
            "ok": True,
            "path": str(project_path),
            "project": project_data,
            "message": f"Opened {project_path.name}",
        }

    def _validate_project(self, project: Any) -> str:
        if not isinstance(project, dict):
            return "Project data must be an object."

        if project.get("format") != self.PROJECT_FORMAT:
            return "Project format is not supported."

        if project.get("version") != self.PROJECT_VERSION:
            return "Project version is not supported."

        if not isinstance(project.get("nodes"), list):
            return "Project nodes must be a list."

        if not isinstance(project.get("connections"), list):
            return "Project connections must be a list."

        return ""

    def _nai_path(self, path: str) -> Path:
        project_path = Path(path)

        if project_path.suffix.lower() != ".nai":
            project_path = project_path.with_suffix(".nai")

        return project_path

    def _as_dict(self, value: Any) -> dict[str, Any]:
        if isinstance(value, dict):
            return value

        if hasattr(value, "toVariant"):
            variant_value = value.toVariant()
            if isinstance(variant_value, dict):
                return variant_value

        return {}

    def _cancelled_result(self, message: str) -> dict[str, Any]:
        return {
            "ok": False,
            "cancelled": True,
            "path": "",
            "project": {},
            "message": message,
        }

    def _error_result(self, message: str) -> dict[str, Any]:
        return {
            "ok": False,
            "cancelled": False,
            "path": "",
            "project": {},
            "message": message,
        }
