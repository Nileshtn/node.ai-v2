from __future__ import annotations

import sys
from pathlib import Path

from PySide6.QtCore import QUrl
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtWidgets import QApplication

from backend.graph_runtime import GraphRuntime
from backend.project_files import ProjectFiles


def main() -> int:
    app = QApplication(sys.argv)
    app.setApplicationName("Node.ai")
    app.setOrganizationName("Node.ai")

    engine = QQmlApplicationEngine()
    graph_runtime = GraphRuntime()
    project_files = ProjectFiles()
    engine.rootContext().setContextProperty("graphRuntime", graph_runtime)
    engine.rootContext().setContextProperty("projectFiles", project_files)

    qml_path = Path(__file__).resolve().parent / "qml" / "Main.qml"
    engine.load(QUrl.fromLocalFile(str(qml_path)))

    if not engine.rootObjects():
        return 1

    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
