package com.bolour.util.scala.common

/**
  * Frequency distribution for a list of values.
  *
  * @param frequencies The frequencies: represented for each value as a non-negative integer.
  */
case class FrequencyDistribution[T](frequencies: List[(T, Int)]) {

  val frequencyMap = Map(frequencies:_*)

  /**
    * Cumulative distribution function.
    */
  val distribution = frequencies.tail.scanLeft(frequencies.head) (
    (cumulative, element) => (cumulative, element) match {
      case ((letter, cumWeight), (nextLetter, weight)) =>
        (nextLetter, cumWeight + weight)
    }
  )

  val maxDistribution: Int = distribution.last._2

  /**
    * Get a random value according to the frequencies in this distribution.
    */
  def randomValue(): T = {
    val distLevel: Int = (Math.random() * maxDistribution).toInt
    distribution.find(_._2 >= distLevel).get._1
  }

  /**
    * Get the least frequent value among a given set of values.
    */
  def leastFrequentValue(values: List[T]): Option[T] = {
    def freq(value: T) = frequencyMap(value)
    def least(vs: List[T]): T =
      vs.reduce( (v1, v2) => if (freq(v1) <= freq(v2)) v1 else v2 )
    values match {
      case Nil => None
      case _ => Some(least(values))
    }
  }

  /**
    * Normalize the letter frequencies to obtain a given rough total
    * return the normalized frequencies and the actual total.
    */
  def normalizedFrequencies(roughTotal: Int): (Map[T, Int], Int) = {
    val factor: Float = roughTotal.toFloat / maxDistribution.toFloat
    def normalizer(frequency: Int) = Math.round(frequency * factor).max(1)

    val normalized = frequencyMap mapValues normalizer
    val actualTotal = normalized.values.sum
    (normalized, actualTotal)
  }
}
