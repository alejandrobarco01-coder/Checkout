package com.example.data.network

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass
import retrofit2.http.GET
import retrofit2.http.Query

@JsonClass(generateAdapter = true)
data class WeatherResponse(
    @Json(name = "name") val name: String?,
    @Json(name = "main") val main: MainInfo?,
    @Json(name = "weather") val weather: List<WeatherInfo>?
)

@JsonClass(generateAdapter = true)
data class MainInfo(
    @Json(name = "temp") val temp: Double?, // Celsius (assuming metric unit system)
    @Json(name = "temp_min") val tempMin: Double?,
    @Json(name = "temp_max") val tempMax: Double?,
    @Json(name = "humidity") val humidity: Double?
)

@JsonClass(generateAdapter = true)
data class WeatherInfo(
    @Json(name = "main") val main: String?, // "Rain", "Snow", "Clear", etc.
    @Json(name = "description") val description: String?,
    @Json(name = "icon") val icon: String?
)

interface WeatherService {
    @GET("data/2.5/weather")
    suspend fun getCurrentWeather(
        @Query("lat") lat: Double,
        @Query("lon") lon: Double,
        @Query("appid") apiKey: String,
        @Query("units") units: String = "metric"
    ): WeatherResponse
}
