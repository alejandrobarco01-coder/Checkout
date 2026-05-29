package com.example.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "checklist_contexts")
data class ChecklistContext(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val name: String,
    val icon: String, // Emoji representation
    val colorHex: String, // Hex color
    val isPremium: Boolean = false
)
