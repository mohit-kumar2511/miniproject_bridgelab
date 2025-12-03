import React from "react"

function gradeMood(g) {
  if (!g) return "bigGrade"
  if (g === "A" || g === "A+") return "bigGrade good"
  if (g === "B" || g === "C") return "bigGrade ok"
  return "bigGrade bad"
}

export default function StudentDetails(props) {
  const x = props.one
  if (!x) {
    return (
      <div className="boxy dataSolo">
      <div className="btnRow" style={{ marginBottom: 12 }}>
        <div className="miniLabel">📋 Student Details</div>
        <button className="ugBtn gray small" onClick={props.onBack}>
          ← Back
        </button>
      </div>
      <div className="emptyText">❌ No student selected</div>
      </div>
    )
  }

  return (
    <div className="boxy dataSolo">
      <div className="btnRow" style={{ marginBottom: 16 }}>
        <div className="tagRow">
          <span className="tinyTag dark">👤 Student Details</span>
          <span className="tinyTag">🆔 ID #{x.id}</span>
        </div>
        <button className="ugBtn gray small" onClick={props.onBack}>
          ← Back
        </button>
      </div>
      <div className="twoCol" style={{ marginBottom: 20 }}>
        <div>
          <div className="miniLabel">👤 Student Name</div>
          <div className="miniVal" style={{fontSize: '18px', fontWeight: '600', color: '#111827', marginTop: '4px'}}>{x.name}</div>
        </div>
        <div>
          <div className="miniLabel">📚 Section</div>
          <div className="miniVal" style={{fontSize: '18px', fontWeight: '600', color: '#667eea', marginTop: '4px'}}>{x.section}</div>
        </div>
      </div>
      <div className="twoCol" style={{ marginBottom: 20 }}>
        <div>
          <div className="miniLabel">📊 Marks Obtained</div>
          <div className="miniVal" style={{fontSize: '32px', fontWeight: '700', color: '#3b82f6', marginTop: '8px'}}>{x.marks}<span style={{fontSize: '16px', color: '#6b7280', fontWeight: '400'}}>/100</span></div>
          <div className="bubbleRow">
            <span className="bubbleItem">📈 Out of 100</span>
            {x.marks >= 75 ? (
              <span className="bubbleItem" style={{background: 'linear-gradient(135deg, #dcfce7 0%, #bbf7d0 100%)', color: '#166534'}}>🎉 Excellent!</span>
            ) : x.marks >= 40 ? (
              <span className="bubbleItem" style={{background: 'linear-gradient(135deg, #fef3c7 0%, #fde68a 100%)', color: '#92400e'}}>👍 Good Work</span>
            ) : (
              <span className="bubbleItem" style={{background: 'linear-gradient(135deg, #fee2e2 0%, #fecaca 100%)', color: '#991b1b'}}>💪 Keep Trying</span>
            )}
          </div>
        </div>
        <div>
          <div className="miniLabel">⭐ Grade</div>
          <div className={gradeMood(x.grade)}>{x.grade}</div>
        </div>
      </div>
      <div className="tagRow">
        <span className="tinyTag muted">👤 {x.name}</span>
        <span className="tinyTag muted">📚 {x.section}</span>
        <span className="tinyTag muted">📊 {x.marks} marks</span>
        <span className="tinyTag muted">⭐ {x.grade}</span>
      </div>
    </div>
  )
}



