import React, { useState } from "react"

export default function StudentForm(props) {
  const one = props.one || {}
  const [nm, setNm] = useState(one.name || "")
  const [sec, setSec] = useState(one.section || "")
  const [mk, setMk] = useState(one.marks == null ? "" : one.marks)
  const [gr, setGr] = useState(one.grade || "")
  const badMode = one && one.id

  function sendIt(e) {
    e.preventDefault()
    if (!nm || !sec || !mk || !gr) {
      alert("fill everything")
      return
    }
    const body = {
      name: nm,
      section: sec,
      marks: Number(mk),
      grade: gr
    }
    props.onSave(body)
  }

  return (
    <div className="boxy dataSolo">
      <div className="btnRow" style={{ marginBottom: 16 }}>
        <div className="tagRow">
          <span className="tinyTag dark">{badMode ? "✏️ Edit Student" : "➕ Add Student"}</span>
          {one && one.id ? (
            <span className="tinyTag muted">🆔 ID #{one.id}</span>
          ) : null}
        </div>
        <button className="ugBtn gray small" onClick={props.onBack}>
          ← Back
        </button>
      </div>
      <form onSubmit={sendIt} className="formStack">
        <div className="twoCol">
          <div className="formRow">
            <label>👤 Student Name</label>
            <input
              value={nm}
              onChange={(e) => setNm(e.target.value)}
              placeholder="Enter student name"
            />
          </div>
          <div className="formRow">
            <label>📚 Section</label>
            <input
              value={sec}
              onChange={(e) => setSec(e.target.value)}
              placeholder="e.g., A, B, C"
            />
          </div>
        </div>
        <div className="twoCol">
          <div className="formRow">
            <label>📊 Marks (0-100)</label>
            <input
              type="number"
              min="0"
              max="100"
              value={mk}
              onChange={(e) => setMk(e.target.value)}
              placeholder="Enter marks"
            />
          </div>
          <div className="formRow">
            <label>⭐ Grade</label>
            <select value={gr} onChange={(e) => setGr(e.target.value)}>
              <option value="">Select Grade</option>
              <option value="A+">A+ (Excellent)</option>
              <option value="A">A (Very Good)</option>
              <option value="B">B (Good)</option>
              <option value="C">C (Average)</option>
              <option value="D">D (Below Average)</option>
              <option value="F">F (Fail)</option>
            </select>
          </div>
        </div>
        <div className="btnRow">
          <div className="btnChunk">
            <button className="ugBtn green" type="submit">
              {badMode ? "💾 Save Changes" : "✅ Save Student"}
            </button>
            <button
              className="ugBtn gray"
              type="button"
              onClick={() => {
                setNm("")
                setSec("")
                setMk("")
                setGr("")
              }}
            >
              🗑️ Clear
            </button>
          </div>
        </div>
      </form>
      <div className="tinyNote" style={{ marginTop: 12 }}>
        💡 After saving, go back and click "Load Students" to see your changes
      </div>
    </div>
  )
}



