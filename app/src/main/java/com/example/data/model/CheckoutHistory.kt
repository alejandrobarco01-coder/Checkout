package com.example.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "checkout_history")
data class CheckoutHistory(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val timestamp: Long = System.currentTimeMillis(),
    val contextName: String,
    val checkedItems: String, // comma-separated names
    val uncheckedItems: String, // comma-separated names
    val wasSuccessful: Boolean = false
)
