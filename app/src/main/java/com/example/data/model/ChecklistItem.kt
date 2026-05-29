package com.example.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "checklist_items")
data class ChecklistItem(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val contextId: Int,
    val name: String,
    val isChecked: Boolean = false,
    val isAutoSuggested: Boolean = false,
    val suggestedByWeather: String? = null
)
