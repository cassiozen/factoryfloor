import { monaco, configService, postToSwift } from './shared-init.js'

// --- Stacked inline diff editors ---
// Each changed file gets its own diff editor instance, auto-sized to content.
// The page itself scrolls — individual editors do not.

const container = document.getElementById('container')
const emptyState = document.getElementById('empty-state')

// Active diff editors: [{ section, editor, originalModel, modifiedModel }]
let activeDiffs = []

// Line height in pixels — used for height calculation.
// Must match Monaco's lineHeight (default ~19px for 13px font).
const LINE_HEIGHT = 19
const HEADER_HEIGHT = 37 // .diff-header height
const MIN_EDITOR_HEIGHT = 60
const PADDING_LINES = 2

function statusLabel(status) {
  switch (status) {
    case 'A': return 'A'
    case 'M': return 'M'
    case 'D': return 'D'
    case 'R': return 'R'
    default: return 'M'
  }
}

function statusClass(status) {
  switch (status) {
    case 'A': return 'added'
    case 'M': return 'modified'
    case 'D': return 'deleted'
    case 'R': return 'renamed'
    default: return 'modified'
  }
}

function formatFilePath(filePath) {
  const lastSlash = filePath.lastIndexOf('/')
  if (lastSlash === -1) return filePath
  const dir = filePath.substring(0, lastSlash + 1)
  const name = filePath.substring(lastSlash + 1)
  return `<span class="dir">${dir}</span>${name}`
}

function calculateEditorHeight(originalText, modifiedText) {
  const origLines = originalText ? originalText.split('\n').length : 0
  const modLines = modifiedText ? modifiedText.split('\n').length : 0
  // Use the larger of the two + padding for diff decorations
  const lines = Math.max(origLines, modLines) + PADDING_LINES
  return Math.max(lines * LINE_HEIGHT, MIN_EDITOR_HEIGHT)
}

function clearDiffs() {
  for (const diff of activeDiffs) {
    diff.editor.dispose()
    diff.originalModel.dispose()
    diff.modifiedModel.dispose()
    diff.section.remove()
  }
  activeDiffs = []
}

/**
 * Set the files to display diffs for.
 * @param {Array<{filePath: string, status: string, languageId: string, originalText: string, modifiedText: string}>} files
 */
function setFiles(files) {
  clearDiffs()

  if (!files || files.length === 0) {
    emptyState.classList.add('visible')
    return
  }
  emptyState.classList.remove('visible')

  for (const file of files) {
    const section = document.createElement('div')
    section.className = 'diff-section'

    // File header
    const header = document.createElement('div')
    header.className = 'diff-header'
    header.innerHTML = `
      <span class="status-badge ${statusClass(file.status)}">${statusLabel(file.status)}</span>
      <span class="file-path">${formatFilePath(file.filePath)}</span>
    `
    section.appendChild(header)

    // Editor container
    const editorContainer = document.createElement('div')
    editorContainer.className = 'diff-editor-container'
    const height = calculateEditorHeight(file.originalText, file.modifiedText)
    editorContainer.style.height = `${height}px`
    section.appendChild(editorContainer)

    container.appendChild(section)

    // Create models
    const originalModel = monaco.editor.createModel(
      file.originalText || '',
      file.languageId || 'plaintext'
    )
    const modifiedModel = monaco.editor.createModel(
      file.modifiedText || '',
      file.languageId || 'plaintext'
    )

    // Create inline diff editor
    const diffEditor = monaco.editor.createDiffEditor(editorContainer, {
      automaticLayout: true,
      renderSideBySide: false,
      readOnly: true,
      originalEditable: false,
      enableSplitViewResizing: false,
      minimap: { enabled: false },
      fontSize: 13,
      fontFamily: 'Menlo, monospace',
      lineNumbers: 'on',
      scrollBeyondLastLine: false,
      renderOverviewRuler: false,
      scrollbar: {
        vertical: 'hidden',
        horizontal: 'auto',
        verticalScrollbarSize: 0,
        horizontalScrollbarSize: 8,
        useShadows: false,
        alwaysConsumeMouseWheel: false,
        handleMouseWheel: false
      },
      overviewRulerLanes: 0,
      hideCursorInOverviewRuler: true,
      stickyScroll: { enabled: false },
      padding: { top: 4, bottom: 4 },
      renderIndicators: true,
      renderMarginRevertIcon: false,
      hideUnchangedRegions: { enabled: true }
    })

    diffEditor.setModel({
      original: originalModel,
      modified: modifiedModel
    })

    // Resize after diff computation completes
    diffEditor.onDidUpdateDiff(() => {
      resizeDiffEditor(diffEditor, editorContainer)
    })

    activeDiffs.push({
      section,
      editor: diffEditor,
      originalModel,
      modifiedModel
    })
  }
}

/**
 * Resize a diff editor container to fit its content (no scrollbar needed).
 */
function resizeDiffEditor(diffEditor, editorContainer) {
  const modifiedEditor = diffEditor.getModifiedEditor()
  // contentHeight gives the exact pixel height of the content
  const contentHeight = modifiedEditor.getContentHeight()
  const newHeight = Math.max(contentHeight + 8, MIN_EDITOR_HEIGHT)
  editorContainer.style.height = `${newHeight}px`
  diffEditor.layout()
}

window.diffAPI = {
  setFiles,

  clear() {
    clearDiffs()
    emptyState.classList.add('visible')
  },

  setTheme(isDark) {
    configService.updateValue('workbench.colorTheme', isDark ? 'Dark Modern' : 'Light Modern')
    document.documentElement.style.colorScheme = isDark ? 'dark' : 'light'
  },

  layout() {
    for (const diff of activeDiffs) {
      diff.editor.layout()
    }
  }
}

// Signal readiness to Swift
postToSwift({ type: 'ready' })

// Reveal after theme is painted
setTimeout(() => document.body.classList.remove('loading'))
