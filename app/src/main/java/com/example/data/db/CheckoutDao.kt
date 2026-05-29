package com.example.data.db

import androidx.room.*
import com.example.data.model.ChecklistContext
import com.example.data.model.ChecklistItem
import com.example.data.model.CheckoutHistory
import com.example.data.model.UserProfile
import kotlinx.coroutines.flow.Flow

@Dao
interface CheckoutDao {

    // Contexts
    @Query("SELECT * FROM checklist_contexts")
    fun getAllContexts(): Flow<List<ChecklistContext>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertContext(context: ChecklistContext): Long

    @Update
    suspend fun updateContext(context: ChecklistContext)

    @Delete
    suspend fun deleteContext(context: ChecklistContext)

    @Query("SELECT * FROM checklist_contexts WHERE id = :id")
    suspend fun getContextById(id: Int): ChecklistContext?

    // Items
    @Query("SELECT * FROM checklist_items WHERE contextId = :contextId")
    fun getItemsForContext(contextId: Int): Flow<List<ChecklistItem>>

    @Query("SELECT * FROM checklist_items WHERE contextId = :contextId")
    suspend fun getItemsForContextSync(contextId: Int): List<ChecklistItem>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertItem(item: ChecklistItem): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertItems(items: List<ChecklistItem>)

    @Update
    suspend fun updateItem(item: ChecklistItem)

    @Delete
    suspend fun deleteItem(item: ChecklistItem)

    @Query("DELETE FROM checklist_items WHERE contextId = :contextId")
    suspend fun deleteItemsByContextId(contextId: Int)

    @Query("DELETE FROM checklist_items WHERE id = :id")
    suspend fun deleteItemById(id: Int)

    @Query("DELETE FROM checklist_items WHERE contextId = :contextId AND isAutoSuggested = 1")
    suspend fun deleteAutoSuggestedItems(contextId: Int)

    // History
    @Query("SELECT * FROM checkout_history ORDER BY timestamp DESC")
    fun getAllHistory(): Flow<List<CheckoutHistory>>

    @Query("SELECT * FROM checkout_history ORDER BY timestamp DESC")
    suspend fun getAllHistorySync(): List<CheckoutHistory>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertHistory(history: CheckoutHistory): Long

    @Query("DELETE FROM checkout_history")
    suspend fun clearHistory()

    // Profile Settings
    @Query("SELECT * FROM user_profile WHERE id = 1 LIMIT 1")
    fun getUserProfileFlow(): Flow<UserProfile?>

    @Query("SELECT * FROM user_profile WHERE id = 1 LIMIT 1")
    suspend fun getUserProfileSync(): UserProfile?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUserProfile(profile: UserProfile)
}
