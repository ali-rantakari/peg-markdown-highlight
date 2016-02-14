/* PEG Markdown Highlight
 * Copyright 2011-2016 Ali Rantakari -- http://hasseg.org
 * Licensed under the GPL2+ and MIT licenses (see LICENSE for more info).
 * 
 * mainwindow.cpp
 * 
 * Qt 4.7 example for highlighting a rich text widget.
 */

#include <QtGui>

#include "mainwindow.h"

MainWindow::MainWindow(QWidget *parent) : QMainWindow(parent)
{
    setupFileMenu();
    setupEditor();

    setCentralWidget(editor);
    setWindowTitle(tr("PEG Markdown Highlight Example"));
}

void MainWindow::newFile()
{
    editor->clear();
}

void MainWindow::openFile(const QString &path)
{
    QString fileName = path;

    if (fileName.isNull())
        fileName = QFileDialog::getOpenFileName(this,
            tr("Open File"), "", "Markdown Files (*.mdtext *.md *.markdown *.txt *.text)");

    if (!fileName.isEmpty()) {
        QFile file(fileName);
        if (file.open(QFile::ReadOnly | QFile::Text))
            editor->setPlainText(file.readAll());
    }
}

void MainWindow::setupEditor()
{
    QFont font;
    font.setFamily("Courier");
    font.setFixedPitch(true);
    font.setPointSize(14);

    editor = new QTextEdit;
    editor->setFont(font);

    QFile file(":/big.md");
    if (file.open(QFile::ReadOnly | QFile::Text))
        editor->setPlainText(file.readAll());

    highlighter = new HGMarkdownHighlighter(editor->document(), 1000);
}

void MainWindow::setupFileMenu()
{
    QMenu *fileMenu = new QMenu(tr("&File"), this);
    menuBar()->addMenu(fileMenu);

    fileMenu->addAction(tr("&New"), this, SLOT(newFile()),
                        QKeySequence::New);

    fileMenu->addAction(tr("&Open..."), this, SLOT(openFile()),
                        QKeySequence::Open);
                        
    fileMenu->addAction(tr("E&xit"), qApp, SLOT(quit()),
                        QKeySequence::Quit);
}
