-- phpMyAdmin SQL Dump
-- version 3.1.1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Apr 24, 2009 at 10:17 PM
-- Server version: 5.0.51
-- PHP Version: 5.2.4-2ubuntu5.6

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `elkm1`
--

-- --------------------------------------------------------

--
-- Table structure for table `area_log`
--

CREATE TABLE IF NOT EXISTS `area_log` (
  `id` int(11) NOT NULL auto_increment,
  `area_number` int(11) NOT NULL,
  `area_name` varchar(30) NOT NULL,
  `status` varchar(20) NOT NULL,
  `alarm_status` varchar(20) NOT NULL,
  `updated_at` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `area_statuses`
--

CREATE TABLE IF NOT EXISTS `area_statuses` (
  `id` int(11) NOT NULL auto_increment,
  `area_number` int(11) NOT NULL,
  `name` varchar(30) NOT NULL,
  `status` varchar(20) NOT NULL default 'closed',
  `alarm_status` varchar(20) NOT NULL,
  `updated_at` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `zone_number` (`area_number`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- Table structure for table `output_log`
--

CREATE TABLE IF NOT EXISTS `output_log` (
  `id` int(11) NOT NULL auto_increment,
  `output_name` varchar(30) NOT NULL,
  `time_open` datetime default NULL,
  `time_close` datetime default NULL,
  `output_number` int(11) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `output_statuses`
--

CREATE TABLE IF NOT EXISTS `output_statuses` (
  `id` int(11) NOT NULL auto_increment,
  `output_number` int(11) NOT NULL,
  `name` varchar(30) NOT NULL,
  `status` varchar(20) NOT NULL default 'closed',
  `updated_at` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `zone_number` (`output_number`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- Table structure for table `zone_log`
--

CREATE TABLE IF NOT EXISTS `zone_log` (
  `id` int(11) NOT NULL auto_increment,
  `zone_number` int(11) NOT NULL,
  `zone` varchar(30) NOT NULL,
  `time_open` datetime default NULL,
  `time_close` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `zone` (`zone`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `zone_statuses`
--

CREATE TABLE IF NOT EXISTS `zone_statuses` (
  `id` int(11) NOT NULL auto_increment,
  `zone_number` int(11) NOT NULL,
  `name` varchar(30) NOT NULL,
  `status` varchar(20) NOT NULL default 'closed',
  `updated_at` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `zone_number` (`zone_number`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 ROW_FORMAT=DYNAMIC;
