import React from "react"

function getChip(grade) {
  if (!grade) return "chip"
  if (grade === "A" || grade === "A+" || grade === "B") return "chip good"
  if (grade === "C") return "chip ok"
  return "chip bad"
}

export default function StudentList(props) {
  const stuff = props.data || []

  return (
    <div className="boxy dataSolo">
      <div className="btnRow" style={{ marginBottom: 16 }}>
        <div className="btnChunk">
          <button className="ugBtn blue small" onClick={props.onLoad} disabled={props.loading}>
            {props.loading ? "⏳ Loading..." : "📥 Load Students"}
          </button>
          <button className="ugBtn green small" onClick={props.onAdd}>
            ➕ Add Student
          </button>
        </div>
        <div className="tinyNote">
          💡 Tip: Click Load Students after making changes
        </div>
      </div>
      {stuff.length === 0 ? (
        <div className="emptyText">📭 No students found. Add your first student! 🎓</div>
      ) : (
        <table className="listTable">
          <thead>
            <tr>
              <th>🆔 ID</th>
              <th>👤 Name</th>
              <th>📚 Section</th>
              <th>📊 Marks</th>
              <th>⭐ Grade</th>
              <th>⚙️ Actions</th>
            </tr>
          </thead>
          <tbody>
            {stuff.map((x) => (
              <tr key={x.id}>
                <td>
                  <span className="idDot">{x.id}</span>
                </td>
                <td>{x.name}</td>
                <td>{x.section}</td>
                <td>{x.marks}</td>
                <td>
                  <span className={getChip(x.grade)}>{x.grade}</span>
                </td>
                <td>
                  <div className="btnChunk">
                    <button
                      className="ugBtn gray small"
                      onClick={() => props.onView(x)}
                    >
                      👁️ View
                    </button>
                    <button
                      className="ugBtn yellow small"
                      onClick={() => props.onEdit(x)}
                    >
                      ✏️ Edit
                    </button>
                    <button
                      className="ugBtn red small"
                      onClick={() => props.onDelete(x)}
                    >
                      🗑️ Delete
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  )
}



